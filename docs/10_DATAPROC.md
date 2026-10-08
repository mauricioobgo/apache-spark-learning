# 10 — Dataproc en GCP

> Cuando ya manejás Spark local y querés correr contra un cluster real.

## ¿Qué es Dataproc?

Un servicio **managed** de GCP para correr Spark y Hadoop. Te abstrae del
cluster manager: vos le decís cuántas máquinas querés y él se ocupa.

Dos modos:

- **Standard (VM-based)**: un cluster persistente de VMs. Vos las pagás
  mientras existen.
- **Serverless (Dataproc Serverless for Spark)**: mandás jobs, GCP asigna
  recursos, ejecuta, y libera. Pagas solo por los segundos de ejecución.

Para aprender, **Serverless es más barato y más simple**. Para workloads
persistentes, **Standard** te da control fino.

---

## 0. Prerrequisitos

```bash
# Instalá gcloud
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Autenticá
gcloud auth login
gcloud auth application-default login

# Creá o seleccioná un proyecto con billing habilitado
gcloud config set project TU_PROYECTO
gcloud services enable dataproc.googleapis.com \
    compute.googleapis.com \
    storage.googleapis.com \
    bigquery.googleapis.com
```

⚠️ **Costos**: Dataproc cobra por segundo de VM. Un cluster chico
(`n1-standard-2` × 2 nodos) cuesta ~$0.10/hora. **Apagá siempre el cluster
después de usarlo** o usá Serverless.

---

## 1. Subí un script a GCS

```bash
# Creá un bucket para los artefactos
BUCKET="gs://spark-learning-${USER}-$(date +%s)"
gsutil mb -l us-central1 $BUCKET

# Subí el script
gsutil cp gcp/scripts/wordcount.py $BUCKET/

# Subí un dataset de ejemplo
gsutil cp local/data/sample/quijote.txt $BUCKET/
```

## 2. Cluster efímero con `gcloud dataproc jobs submit`

**Serverless** (recomendado para empezar):

```bash
gcloud dataproc batches submit pyspark \
    gs://TU_BUCKET/wordcount.py \
    --region=us-central1 \
    --jars=gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.27.0.jar \
    --properties="spark.executor.instances=2" \
    -- --input=gs://TU_BUCKET/quijote.txt --output=gs://TU_BUCKET/out
```

**Standard** (cluster efímero):

```bash
gcloud dataproc clusters create spark-ephemeral \
    --region=us-central1 \
    --zone=us-central1-a \
    --master-boot-disk-size=30GB \
    --worker-boot-disk-size=30GB \
    --num-workers=2 \
    --worker-machine-type=n1-standard-2 \
    --master-machine-type=n1-standard-2 \
    --image-version=2.1-debian11 \
    --optional-components=JUPYTER \
    --max-idle=30m   # se apaga solo a los 30 min de inactividad

# Mandá un job
gcloud dataproc jobs submit pyspark \
    gs://TU_BUCKET/wordcount.py \
    --cluster=spark-ephemeral \
    --region=us-central1 \
    -- --input=gs://TU_BUCKET/quijote.txt --output=gs://TU_BUCKET/out

# Cuando termines
gcloud dataproc clusters delete spark-ephemeral --region=us-central1
```

⚠️ `--max-idle=30m` es la red de seguridad. **No te olvides** de hacer
delete igual — el cluster vive aunque esté idle, salvo que `max-idle` lo
mate.

## 3. Desde PySpark, leé GCS y escribí a BigQuery

El connector de BigQuery para Spark está en
`gs://spark-lib/bigquery/...`. Una vez que lo agregás a `--jars`, podés
usar:

```python
# Lectura
df = spark.read.format("bigquery") \
    .option("table", "bigquery-public-data.samples.shakespeare") \
    .load()

# Escritura
df.write.format("bigquery") \
    .option("table", "mi_proyecto.mi_dataset.mi_tabla") \
    .mode("overwrite") \
    .save()
```

## 4. Monitoreo

- **Cluster UI**: el master expone la Spark UI en
  `http://CLUSTER_NAME-m:8088` (gRPC forward via `gcloud compute ssh ...`).
- **Cloud Console**: <https://console.cloud.google.com/dataproc/batches>
  ves runs, logs y métricas integradas.
- **Cloud Logging**: todos los logs caen a `projects/PROYECTO/logs/dataproc`.

## 5. IAM mínimo

Para que un job lea GCS y BigQuery, la cuenta de servicio del cluster
(generalmente la default Compute Engine SA) necesita:

- `roles/storage.objectAdmin` (en el bucket específico, no todo el proyecto)
- `roles/bigquery.dataViewer` + `roles/bigquery.jobUser` (a nivel dataset)

Evitá darle `Owner` o `Editor` a nivel proyecto. **Menos permisos = menos
blast radius si algo sale mal.**

## 6. Estimación de costos (ejemplo real)

Job de 10 minutos, 4 workers `n1-standard-4`:
- Master: 1 × n1-standard-2 × 10/60 h = ~$0.03
- Workers: 4 × n1-standard-4 × 10/60 h = ~$0.50
- Disco: ~$0.02
- **Total: ~$0.55**

Para aprender, **mantenete en Serverless con `n2-standard-2`** y
verificá la facturación en <https://console.cloud.google.com/billing>.

---

## Cuándo NO usar Dataproc

- **Datos < 10 GB**: con Pandas alcanza, no necesitás cluster.
- **Streaming en tiempo real con latencia < 1s**: mirá Beam + Dataflow.
- **ML con GPUs**: Dataproc no es el camino más barato; usá Vertex AI.
- **ETL SQL puro**: BigQuery + dbt es más simple y barato.

## Lo que sigue

Corré `gcp/scripts/setup_cluster.sh` y después `gcp/scripts/submit_wordcount.sh`.
Cuando funcione, probá el notebook `gcp/notebooks/01_dataproc_quickstart.ipynb`
(lo creamos en el próximo paso del roadmap).

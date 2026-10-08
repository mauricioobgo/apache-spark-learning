# 00 — Setup local (Docker)

Esta guía te lleva de cero a un Jupyter con PySpark corriendo en ~5 minutos.

## 1. Verifica tu máquina

Necesitas:
- Docker 24+ y docker compose v2
- 8 GB RAM libres
- 5 GB disco libre (la imagen pesa ~1.5 GB)

```bash
docker --version       # Docker version 24.0.0 o superior
docker compose version # Docker Compose version v2.x
```

## 2. Levanta el entorno

```bash
cd apache-spark-learning
docker compose -f local/docker-compose.yml up -d
```

La primera vez descarga la imagen. Tarda entre 1 y 5 minutos según tu
conexión. Los siguientes arranques son instantáneos.

## 3. Obtén la URL de Jupyter

```bash
docker compose -f local/docker-compose.yml logs spark-master | grep token
```

Vas a ver algo como:
```
http://127.0.0.1:8888/lab?token=abc123def456
```

Como fijamos `--NotebookApp.token=spark` en el compose, también podés entrar
con `http://localhost:8888` y pegar el token `spark` cuando lo pida.

## 4. Smoke test

Abrí un notebook nuevo y corré:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("smoke-test") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

df = spark.createDataFrame([(1, "a"), (2, "b")], ["id", "letra"])
df.show()
spark.stop()
```

Deberías ver:
```
+---+------+
| id|letra|
+---+------+
|  1|     a|
|  2|     b|
+---+------+
```

## 5. Monitoreá lo que pasa

- **Jupyter Lab**: <http://localhost:8888>
- **Spark UI (driver)**: <http://localhost:4040>
- **Spark master UI**: <http://localhost:8080>
- **Spark worker UI**: <http://localhost:8081>

Mientras un notebook está corriendo, mirá el puerto 4040: ahí ves los stages,
shuffles, memoria y tasks en tiempo real. Es la mejor forma de aprender qué
está haciendo Spark por debajo.

## 6. Datos de ejemplo

Los notebooks leen archivos de `local/data/sample/`. Empezamos con CSVs y
Parquet sintéticos. Más adelante añadimos un dataset real (~50 MB) para los
ejercicios de ETL y streaming.

## 7. Apagar el entorno

```bash
docker compose -f local/docker-compose.yml down
```

Para borrar también la imagen:
```bash
docker compose -f local/docker-compose.yml down --rmi all
```

---

## Problemas comunes

### El puerto 8888 está ocupado

Cambialo en `docker-compose.yml`:
```yaml
ports:
  - "9999:8888"   # usás localhost:9999
```

### El contenedor no arranca y dice `Cannot connect to Docker daemon`

Docker Desktop no está corriendo. Abrilo y esperá a que diga "Docker is
running".

### Spark UI muestra "No stages found" después de correr una celda

El UI 4040 es del driver *vivo*. Cuando el notebook termina, el driver se
apaga y la UI desaparece. Para mantener la UI entre celdas, corré Spark con
`spark.ui.retainedStages=100` o exportá `PYSPARK_SUBMIT_ARGS` con esa flag.

### Quiero más workers

Agregá más servicios `spark-worker` al compose cambiando el nombre. Cada
worker es un contenedor con su propio puerto (8081, 8082, ...).

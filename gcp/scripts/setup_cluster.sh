#!/usr/bin/env bash
# Crea (o recrea) un cluster Dataproc efímero optimizado para aprendizaje.
#
# Requisitos:
#   - gcloud CLI instalado y autenticado (gcloud auth login)
#   - billing habilitado en el proyecto
#   - APIs: dataproc, compute, storage habilitadas
#
# Uso:
#   ./gcp/scripts/setup_cluster.sh
#   export CLUSTER=spark-learning
#   ./gcp/scripts/submit_wordcount.sh

set -euo pipefail

REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"
CLUSTER="${CLUSTER:-spark-ephemeral}"
PROJECT="${PROJECT:-$(gcloud config get-value project)}"
BUCKET="${BUCKET:-spark-learning-${USER}-$(date +%s)}"

echo "→ Proyecto: $PROJECT"
echo "→ Región:   $REGION"
echo "→ Cluster:  $CLUSTER"
echo "→ Bucket:   gs://$BUCKET"

# 1. Habilitar APIs
echo "→ Habilitando APIs..."
gcloud services enable dataproc.googleapis.com \
    compute.googleapis.com \
    storage.googleapis.com \
    --project="$PROJECT" >/dev/null

# 2. Crear bucket
echo "→ Creando bucket..."
gsutil mb -p "$PROJECT" -l "$REGION" "gs://$BUCKET" 2>/dev/null || echo "  (bucket ya existe)"

# 3. Subir assets
echo "→ Subiendo assets..."
gsutil cp gcp/scripts/wordcount.py "gs://$BUCKET/"
# (opcional) gsutil cp data/quijote.txt "gs://$BUCKET/"

# 4. Crear cluster efímero
echo "→ Creando cluster Dataproc (puede tardar 2-3 min)..."
gcloud dataproc clusters create "$CLUSTER" \
    --project="$PROJECT" \
    --region="$REGION" \
    --zone="$ZONE" \
    --master-machine-type=n1-standard-2 \
    --master-boot-disk-size=30GB \
    --worker-machine-type=n1-standard-2 \
    --worker-boot-disk-size=30GB \
    --num-workers=2 \
    --image-version=2.1-debian11 \
    --optional-components=JUPYTER \
    --max-idle=30m

cat <<EOF

✅ Listo.

Próximos pasos:
  export CLUSTER=$CLUSTER
  export BUCKET=$BUCKET
  ./gcp/scripts/submit_wordcount.sh

Para conectarte al Jupyter del master (opcional):
  gcloud compute ssh $CLUSTER-m --region=$REGION -- -L 8888:localhost:8888
  → Abrí http://localhost:8888

Cuando termines:
  gcloud dataproc clusters delete $CLUSTER --region=$REGION
EOF

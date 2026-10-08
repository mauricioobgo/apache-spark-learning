#!/usr/bin/env bash
# Envía el job wordcount a un cluster Dataproc existente.
# Uso:
#   export CLUSTER=spark-ephemeral
#   export BUCKET=spark-learning-...
#   ./gcp/scripts/submit_wordcount.sh

set -euo pipefail

REGION="${REGION:-us-central1}"
CLUSTER="${CLUSTER:?Necesitás exportar CLUSTER (ej: export CLUSTER=spark-ephemeral)}"
BUCKET="${BUCKET:?Necesitás exportar BUCKET (ej: export BUCKET=spark-learning-...)}"
INPUT="${INPUT:-gs://$BUCKET/quijote.txt}"
OUTPUT="${OUTPUT:-gs://$BUCKET/wordcount_out}"

# Sube el quijote si no existe
if ! gsutil -q stat "$INPUT"; then
    echo "→ Subiendo quijote.txt a $INPUT..."
    gsutil cp local/data/sample/quijote.txt "$INPUT"
fi

echo "→ Enviando job a $CLUSTER..."
gcloud dataproc jobs submit pyspark \
    "gs://$BUCKET/wordcount.py" \
    --project="$(gcloud config get-value project)" \
    --region="$REGION" \
    --cluster="$CLUSTER" \
    -- --input="$INPUT" --output="$OUTPUT"

echo ""
echo "✅ Job terminado. Output en:"
echo "  $OUTPUT"
echo ""
echo "Para leerlo:"
echo "  gsutil cat $OUTPUT/part-*.csv | head -20"

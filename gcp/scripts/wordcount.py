#!/usr/bin/env python3
"""
WordCount con PySpark — el "Hello World" de Spark distribuido.

Uso local:
    docker compose -f local/docker-compose.yml exec spark-master \
        spark-submit /home/jovyan/work/gcp/scripts/wordcount.py \
        /home/jovyan/work/data/sample/quijote.txt \
        /home/jovyan/work/data/sample/wordcount_out

Uso Dataproc:
    gcloud dataproc jobs submit pyspark \
        gs://TU_BUCKET/wordcount.py \
        --cluster=spark-ephemeral \
        --region=us-central1 \
        -- --input=gs://TU_BUCKET/quijote.txt --output=gs://TU_BUCKET/out
"""
import argparse
import sys
import re

from pyspark.sql import SparkSession, functions as F


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Ruta al archivo de texto (local o gs://)")
    parser.add_argument("--output", required=True, help="Ruta destino (local o gs://)")
    args = parser.parse_args()

    spark = SparkSession.builder.appName("wordcount").getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    # Leer
    text = spark.read.text(args.input)

    # Tokenizar: split, lowercase, drop empty, drop non-alpha
    words = (
        text
        .select(F.explode(F.split(F.col("value"), r"\s+")).alias("word"))
        .select(F.lower(F.regexp_replace(F.col("word"), r"[^a-záéíóúñü]", "")).alias("word"))
        .filter(F.col("word") != "")
    )

    # Contar
    counts = words.groupBy("word").count().orderBy(F.col("count").desc())

    # Escribir (en CSV con header para que sea legible; en Parquet para perf)
    (
        counts.write
        .mode("overwrite")
        .csv(args.output)
    )

    print(f"[wordcount] OK — escrito en {args.output}")
    counts.show(20, truncate=False)
    spark.stop()


if __name__ == "__main__":
    main()

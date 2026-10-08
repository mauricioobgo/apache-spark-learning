# Apache Spark (PySpark) + GCP Dataproc

> Repositorio de aprendizaje: desde PySpark local en Docker hasta clusters de
> Dataproc en producción. Diseñado para correr en orden y dejar evidencia de
> cada hito.

[![Spark](https://img.shields.io/badge/Apache%20Spark-3.5.x-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![GCP](https://img.shields.io/badge/GCP-Dataproc-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com/dataproc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Qué vas a aprender

| # | Módulo | Qué cubre | Estado |
|---|--------|-----------|--------|
| 0 | **Setup** | Docker local con PySpark + Jupyter | ⏳ |
| 1 | **Fundamentos** | RDD, DataFrame, SparkSQL, transforms vs actions, lazy evaluation | ⏳ |
| 2 | **ETL + Delta Lake** | Parquet, particionado, Delta, MERGE INTO, time travel | ⏳ |
| 3 | **Structured Streaming** | Windowing, watermarks, triggers, sinks (Kafka/Delt) | ⏳ |
| 4 | **Cluster & tuning** | Spark UI, partición, shuffle, memoria, AQE | ⏳ |
| 5 | **Dataproc en GCP** | `gcloud dataproc jobs submit`, clusters efímeros, GCS, BigQuery connector | ⏳ |

---

## 🧭 Cómo usar este repo

1. Empieza por **[docs/00_SETUP.md](docs/00_SETUP.md)** — levanta el entorno local.
2. Sigue los notebooks en `local/notebooks/` en orden numérico.
3. Cuando te sientas cómodo, pasa a **[docs/10_DATAPROC.md](docs/10_DATAPROC.md)**.
4. Cada notebook tiene un *checkpoint*: una celda final que imprime `✅ OK` si todo corrió bien.

---

## 📦 Requisitos

- **Docker** >= 24 + **docker compose** v2
- 8 GB RAM libres (Spark come RAM)
- 10 GB disco libre
- Para GCP: `gcloud` CLI autenticado + proyecto con billing habilitado

Verifica con:
```bash
docker --version
docker compose version
df -h /tmp | tail -1
```

---

## 🚀 Quick start (60 segundos)

```bash
git clone https://github.com/mauricioobgo/apache-spark-learning.git
cd apache-spark-learning
docker compose -f local/docker-compose.yml up -d
open http://localhost:8888
```

El primer arranque baja ~1.5 GB (imagen de Spark con Jupyter). Después va al
instante.

---

## 📁 Estructura

```
.
├── README.md                  ← este archivo
├── LICENSE
├── docs/                      ← guías narradas en español
│   ├── 00_SETUP.md
│   ├── 01_FUNDAMENTOS.md
│   ├── 02_ETL_DELTA.md
│   ├── 03_STREAMING.md
│   ├── 04_TUNING.md
│   └── 10_DATAPROC.md
├── local/                     ← todo lo que corre en tu máquina
│   ├── docker-compose.yml
│   ├── notebooks/             ← notebooks numerados
│   └── data/sample/           ← datasets sintéticos pequeños
└── gcp/                       ← todo lo que toca GCP
    ├── scripts/               ← gcloud + spark-submit
    └── terraform/             ← IaC opcional para cluster efímero
```

---

## 🧪 Verificar instalación

Después de levantar Docker:
```bash
docker compose -f local/docker-compose.yml exec spark-master \
  pyspark --version
```

Deberías ver algo como:
```
Welcome to
    ____              __
   / __/__  ___ _____/ /__
  _\ \/ _ \/ _ `/ __/  '_/
 /___/ .__/\_,_/_/ /_/\_\   version 3.5.x
    /_/
```

---

## 🛠 Troubleshooting rápido

| Síntoma | Causa | Fix |
|---------|-------|-----|
| `Cannot find Spark installation dir` | Variable mal seteada | Reinicia el contenedor |
| `JAVA_HOME is not set` | Falta el JDK | `docker compose down && up -d` (la imagen ya lo incluye) |
| Jupyter pide token | Es normal | Lee el log: `docker compose logs spark-master` |
| Puerto 8888 ocupado | Otro Jupyter | Cambia el mapeo en `docker-compose.yml` |

---

## 📚 Recursos

- [Spark: The Definitive Guide (Chambers, Zaharia)](https://www.oreilly.com/library/view/spark-the-definitive/9781491912201/) — biblia
- [Dataproc docs oficiales](https://cloud.google.com/dataproc/docs)
- [Delta Lake docs](https://docs.delta.io/)
- [Spark by examples](https://sparkbyexamples.com/) — recetas cortas

---

## 🤝 Contribuciones

PRs y issues bienvenidos. Mantén el orden numérico de notebooks.

---

_Made with ☕ por mauricioobgo + Hermes._

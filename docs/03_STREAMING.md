# 03 — Structured Streaming

> Spark Streaming moderno: API declarativa basada en DataFrames, mismo
> optimizador, manejo de evento de fin de mundo incluido.

## Conceptos básicos

Un "streaming query" en Spark es **un DataFrame infinito** que se procesa
en micro-batches (o continuo, en modo experimental). La API es la misma que
batch:

```python
stream = spark.readStream.format("rate").load()  # genera filas

query = stream \
    .groupBy(window(stream.timestamp, "1 minute")) \
    .count() \
    .writeStream \
    .outputMode("complete") \
    .format("memory") \
    .start()

query.awaitTermination(30)  # corre 30s y termina
```

## Windowing

Para agregar por ventanas de tiempo:

```python
from pyspark.sql.functions import window

# Tumbling window: eventos de [0, 1m), [1m, 2m), ...
df.groupBy(window(df.event_time, "1 minute")).count()

# Sliding window: ventana de 1m que avanza cada 30s
df.groupBy(window(df.event_time, "1 minute", "30 seconds")).count()
```

## Watermarks

Sin watermark, Spark **espera para siempre** por eventos tarde. El
watermark le dice "descartá eventos con más de X de retraso":

```python
df.withWatermark("event_time", "10 minutes") \
  .groupBy(window(df.event_time, "5 minutes")) \
  .count()
```

Trade-off: a más watermark, más latencia de cierre de ventana, pero menos
memoria.

## Triggers

Controlan **cuándo dispara Spark un micro-batch**:

| Trigger | Cuándo corre | Uso |
|---------|--------------|-----|
| `trigger(processingTime="10s")` | Cada 10s | Default moderno |
| `trigger(once=True)` | Una vez y termina | Backfill batch |
| `trigger(availableNow=True)` | Procesa todo lo disponible y termina | Backfill eficiente |
| `trigger(continuous="1s")` | Latencia ~1s (experimental) | Tiempo real casi real |

**Recomendación 2026**: usá `availableNow=True` para backfills y
`processingTime="N seconds"` para streaming real.

## Output modes

- **append**: solo filas nuevas (no aggregates).
- **update**: filas que cambiaron (default para aggregates con watermark).
- **complete**: reescribe toda la tabla de salida (caro, solo para state
  chico como counts globales).

## Sinks comunes

- `format("delta")` — la opción más usada.
- `format("kafka")` — escribir a otro topic.
- `format("console")` — para debug.
- `format("foreachBatch")` — ejecutar código Python arbitrario por batch.

## Lo que sigue

Notebooks en `local/notebooks/03_streaming/`:
- `01_rate_source_windowing.ipynb`
- `02_watermarks_late_data.ipynb`
- `03_files_source_delta_sink.ipynb`
- `04_kafka_basico.ipynb` (opcional, requiere Kafka corriendo)

# 02 — ETL con Parquet, Particionado y Delta Lake

## Por qué importa

El formato de archivo y la estrategia de particionado son **el 80% del
performance** de cualquier pipeline Spark en producción. Cambiar de CSV a
Parquet pasa un job de 10 minutos a 30 segundos.

## Parquet

- **Columnar**: solo lee las columnas que pedís. CSV lee siempre todo.
- **Comprimido** por default (Snappy).
- **Schema-aware**: los tipos van en el archivo, no hace falta
  especificarlos al leer.

```python
df = spark.read.parquet("s3://bucket/data/")   # lee solo metadatos
df.select("user_id").show()                    # lee SOLO la columna user_id
```

## Particionado

Parquet puede estar **particionado por columnas** (Hive-style):

```
data/year=2026/month=10/day=01/file.parquet
data/year=2026/month=10/day=02/file.parquet
```

Spark usa esa jerarquía para **partition pruning**: si filtrás
`year=2026 AND month=10`, lee solo 2 directorios en vez de todos.

**Reglas**:
- Particioná por columnas de **baja cardinalidad** (fecha, país,
  categoría) — nunca por `user_id`.
- Cada partición debería tener al menos 100 MB (si no, agrupalas).
- No sobre-particiones (miles de archivos chiquitos = metadata hell).

## Delta Lake

Un **formato de tabla** encima de Parquet que añade:

- **ACID transactions**: lecturas consistentes durante escrituras.
- **Time travel**: leer el estado de la tabla de hace N versiones.
- **MERGE / UPDATE / DELETE**: SQL familiar sobre archivos.
- **Schema evolution**: agregar columnas no rompe lecturas viejas.

```python
df.write.format("delta") \
    .mode("append") \
    .partitionBy("year", "month") \
    .save("s3://bucket/delta/events/")

# Time travel
df_old = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("s3://bucket/delta/events/")
```

## Lo que sigue

Notebooks en `local/notebooks/02_etl_delta/`:
- `01_csv_a_parquet.ipynb` — comparación de performance.
- `02_particionado.ipynb` — pruning y dimensionado.
- `03_delta_lake_basico.ipynb` — write/read/MERGE/time travel.

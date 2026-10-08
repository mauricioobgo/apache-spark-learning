# 04 — Cluster y tuning

> Cuando el job tarda 2 horas y "tiene que ser más rápido" es un ticket
> abierto. Este módulo es la checklist que recorrés antes de tirar más
> máquinas al problema.

## El orden importa

Siempre, en este orden:

1. **Datos** — están en el formato correcto? Particionados? Sin columnas
   inútiles?
2. **Lógica** — estás trayendo algo que no necesitás? Hay un shuffle que se
   puede evitar con broadcast?
3. **Configuración** — AQE on? Shuffle partitions razonable? Memoria
   suficiente para el skew?
4. **Recursos** — y solo ahora, más máquinas.

## Adaptive Query Execution (AQE)

Spark 3.x trae AQE on por default. Lo importante que hace:

- **Coalesce shuffle partitions**: une particiones chiquitas al final del
  stage.
- **Optimize skewed joins**: detecta una partición gigante y la subdivide.
- **Convert sort-merge join → broadcast join**: si en runtime la tabla
  "chica" entra en memoria, la convierte automáticamente.

```python
spark.conf.set("spark.sql.adaptive.enabled", "true")   # default true
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
```

## Shuffle partitions

`spark.sql.shuffle.partitions=200` es el default. Es una locura para
cualquier dataset que no sea enorme.

Regla: **target ~100-200 MB por partición post-shuffle**.

```python
# Dataset chico (~1 GB)
spark.conf.set("spark.sql.shuffle.partitions", "8")

# Dataset grande (~1 TB)
spark.conf.set("spark.sql.shuffle.partitions", "2000")
```

## Skew de datos

El problema más común: una key concentra el 80% de las filas. Un
`groupBy` o `join` con esa key hace que un solo task tarde 100× más que
los demás.

Soluciones:
- **AQE skew join** (encenderlo, dejar que Spark lo maneje).
- **Salting**: agregar un sufijo aleatorio a la key problemática,
  agrupar, después quitar el sufijo.
- **Filtrar la key hot** y procesarla aparte.

## Memoria

Tres cosas que mirar:

- `spark.executor.memory`: total del executor (default 1g).
- `spark.memory.fraction` (default 0.6): fracción para execution + storage.
- `spark.memory.storageFraction` (default 0.5): de esa fracción, cuánto es
  para cache vs ejecución.

Si hacés mucho `df.persist()`, bajá `storageFraction` para no robarle a
execution.

## Diagnóstico en la Spark UI

Cuando algo tarda, abrí el puerto 4040 y mirá:

1. **SQL/DataFrame tab**: plan lógico y físico, cuánto tardó cada nodo.
2. **Stages tab**: time breakdown por task. Buscás un task con 100× el
   tiempo medio → skew.
3. **Storage tab**: cuánto tenés cacheado, evictions.
4. **Environment tab**: config efectiva (útil para verificar que tus
   `spark.conf.set` se aplicaron).
5. **Executors tab**: GC time. Si es > 10% del time, falta memoria.

## Lo que sigue

Notebooks en `local/notebooks/04_cluster_tuning/`:
- `01_aqe_demo.ipynb`
- `02_shuffle_partitions.ipynb`
- `03_skew_salting.ipynb`
- `04_caching_y_persist.ipynb`

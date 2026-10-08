# 01 — Fundamentos de Apache Spark

> El core mental que necesitás para no sufrir cuando algo falla.

## ¿Qué es Spark, en una frase?

Un motor de **ejecución distribuida** que coordina tareas a través de un
**cluster** de máquinas para procesar datos que no entran en una sola.

## Los 5 conceptos que importan

### 1. Driver y executors

- **Driver**: tu programa Python. Tiene el `SparkContext`/`SparkSession` y
  planifica el trabajo.
- **Executors**: procesos JVM en los workers. Hacen el trabajo pesado
  (leer, transformar, escribir).
- Entre el driver y los executors corre el **cluster manager** (local,
  Standalone, YARN, Kubernetes, Mesos, Dataproc).

```
┌────────────┐  plan  ┌────────────┐
│   Driver   │◀──────▶│  Master    │
└─────┬──────┘  tasks └─────┬──────┘
      │                     │
      │    ┌────────────┐   │
      └───▶│ Executor 1 │◀──┘
      │    └────────────┘
      │    ┌────────────┐
      └───▶│ Executor 2 │
           └────────────┘
```

### 2. RDD vs DataFrame vs Dataset

| Capa | Tipo | Cuándo | Notas |
|------|------|--------|-------|
| **RDD** | Objeto distribuido de bajo nivel | Casi nunca en PySpark | API vieja, no optimizada |
| **DataFrame** | Tabla distribuida con schema | **El 95% del trabajo** | Catalyst optimiza, Tungsten ejecuta |
| **Dataset** | Tipado fuerte (solo Scala/Java) | Migrar código Scala legacy | PySpark no lo usa |

**Regla práctica**: usá DataFrame siempre. Bajá a RDD solo si necesitás
control de muy bajo nivel o un caso edge que el DataFrame no cubre.

### 3. Lazy evaluation

Spark **no ejecuta nada** hasta que aparece una **action**. Todo lo anterior
son *transformations* que solo construyen un plan lógico.

```python
df = spark.read.csv("data.csv")   # transformation (no lee nada)
df2 = df.filter(df.age > 18)      # transformation (no filtra nada)
df3 = df2.select("name", "age")   # transformation (no selecciona nada)

df3.show()                        # ← AHORA sí se ejecuta todo
df3.count()                       # y acá también
```

**Por qué importa**: Spark ve el plan completo y lo optimiza antes de
ejecutar. Si encadenás 10 transforms y una action al final, Catalyst puede
reordenar, fusionar y eliminar operaciones intermedias.

### 4. Transformations vs Actions

- **Transformations** (lazy): devuelven otro DataFrame.
  - `filter`, `select`, `withColumn`, `join`, `groupBy`, `orderBy`, ...
- **Actions** (ejecutan): devuelven un valor al driver o escriben afuera.
  - `show`, `count`, `collect`, `take`, `write`, `foreach`

Si tu notebook "se cuelga", casi siempre es porque se te coló una action
dónde iba una transform, o porque hiciste `collect()` de un dataset grande
y se trajo todo al driver.

### 5. Shuffle

El **shuffle** es el movimiento de datos entre executors. Es la operación
más cara de Spark. La causa más común:

```python
df.groupBy("key").count()    # shuffle por key
df.join(df2, "key")          # shuffle por key (salvo broadcast hint)
df.orderBy("col")            # shuffle global
```

**Cómo minimizarlo**:
- `spark.sql.shuffle.partitions` no es mágico: si la tabla es chica, bajalo.
- Usá **broadcast joins** cuando una de las tablas entra en memoria:
  `df.join(broadcast(df2), "key")`.
- Filtrá lo más posible **antes** de un groupBy/join.
- Leé la sección de **AQE** (Adaptive Query Execution) — Spark 3.x la trae
  encendida por default y reduce shuffles automáticamente.

## El plan de ejecución

Cualquier action dispara esto:
1. **Parser** → AST.
2. **Analyzer** → resuelve nombres de columnas, tipos.
3. **Optimizer (Catalyst)** → empuja filtros, fusiona operaciones.
4. **Planner** → plan físico (RDD de operaciones concretas).
5. **Scheduler (DAGScheduler)** → divide en stages.
6. **TaskScheduler** → manda tasks a los executors.

Cuando algo tarda mucho, abrí la **Spark UI** (puerto 4040) y mirá el
**DAG visualization** y la pestaña **SQL** (si venís de DataFrame). Ahí
ves los stages, el shuffle, y el tiempo de cada task.

## Lo que sigue

Andá a `local/notebooks/01_fundamentos/` y empezá con el notebook
`01_primer_dataframe.ipynb`.

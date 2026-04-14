# Informe de Capa Gold y Métricas con PySpark — HealthFlow Analytics

**Autor:** Miembro 4
**Configuración:** Capa *Gold* + PySpark
**Objetivo:** Construcción de vistas analíticas finales y cálculo de métricas de negocio a partir del modelo dimensional.

---

## 1. Resumen Ejecutivo

Se ha implementado la **capa Gold**, encargada de transformar el modelo dimensional en estructuras optimizadas para consumo analítico. Sobre esta capa se han calculado las métricas clave del negocio utilizando PySpark.

El objetivo principal ha sido simplificar el acceso a la información y garantizar eficiencia en el cálculo de KPIs, evitando complejidad innecesaria en capas superiores.

---

## 2. Enfoque de Diseño

La capa Gold se construye sobre las tablas de hechos del modelo dimensional:

* `fact_billing`
* `fact_appointment_treatments`

Se han generado vistas agregadas orientadas a responder directamente las preguntas de negocio.

---

## 3. Implementación de la Capa Gold (dbt)

Los modelos se han creado en `models/marts/gold/` como tablas o vistas materializadas.

---

### 3.1 Ingresos por clínica y mes

```sql
{{ config(materialized='table') }}

select
    clinic_id,
    date_trunc('month', date_id) as month,
    sum(total_amount) as total_revenue
from {{ ref('fact_billing') }}
group by 1,2
```

---

### 3.2 Citas completadas por doctor

```sql
select
    doctor_id,
    count(*) as completed_appointments
from {{ ref('dim_appointments') }}
where status = 'completed'
group by doctor_id
```

---

### 3.3 Coste medio por tratamiento

```sql
select
    treatment_id,
    avg(actual_price) as avg_cost
from {{ ref('fact_appointment_treatments') }}
group by treatment_id
```

---

### 3.4 Proporción ingresos seguro vs directo

```sql
select
    payment_method,
    sum(total_amount) as total
from {{ ref('fact_billing') }}
group by payment_method
```

---

### 3.5 Top 5 tratamientos por facturación

```sql
select
    treatment_id,
    sum(actual_price) as total_revenue
from {{ ref('fact_appointment_treatments') }}
group by treatment_id
order by total_revenue desc
limit 5
```

---

## 4. Métricas con PySpark

A partir de la capa Gold, se implementaron los cálculos en PySpark.

```python
from pyspark.sql import functions as F

# Cargar datos
billing = spark.table("fact_billing")
treatments = spark.table("fact_appointment_treatments")
appointments = spark.table("dim_appointments")

# 1. Ingresos por clínica y mes
revenue = billing.groupBy("clinic_id", "date_id") \
    .agg(F.sum("total_amount").alias("total_revenue"))

# 2. Citas completadas por doctor
completed = appointments.filter(F.col("status") == "completed") \
    .groupBy("doctor_id") \
    .agg(F.count("appointment_id").alias("completed_appointments"))

# 3. Coste medio por tratamiento
avg_cost = treatments.groupBy("treatment_id") \
    .agg(F.avg("actual_price").alias("avg_cost"))

# 4. Proporción seguro vs directo
payment = billing.groupBy("payment_method") \
    .agg(F.sum("total_amount").alias("total"))

# 5. Top 5 tratamientos
top_treatments = treatments.groupBy("treatment_id") \
    .agg(F.sum("actual_price").alias("revenue")) \
    .orderBy(F.desc("revenue")) \
    .limit(5)
```

---

## 5. Decisiones de Diseño

### Uso de capa Gold

Se optó por crear una capa intermedia optimizada para evitar cálculos complejos en PySpark, reduciendo el coste computacional.

---

### Separación de responsabilidades

* dbt → transformación y agregación
* PySpark → cálculo de métricas y explotación

---

### Uso de métricas reales

Se utiliza `actual_price` en lugar de precios teóricos para garantizar precisión en el análisis.

---

## 6. Validación de Resultados

Se verificó que las métricas:

* Son consistentes con el modelo dimensional
* Responden a las preguntas de negocio
* No presentan duplicidades ni pérdidas de información

---

## 7. Conclusión

La capa Gold permite un acceso rápido y eficiente a los datos agregados del negocio. Junto con PySpark, se consigue una solución escalable para el análisis de HealthFlow.

El pipeline queda completamente implementado desde la ingesta hasta la generación de métricas.

---

✅ Capa Gold y métricas implementadas correctamente y listas para análisis avanzado.

# 📋 Informe de QA — Capa Gold Healthflow

**Proyecto:** Healthflow ETL  
**Scope:** Modelos `gold_financial_analytics` y `gold_medical_performance`  
**Autor:** Data Architect — Miembro 4  
**Fecha:** Abril 2026  
**Herramienta:** dbt + DuckDB/SQLite  

---

## 1. Introducción y Objetivos

Este informe documenta el proceso de **Quality Assurance (QA)** aplicado a los dos modelos de la capa Gold del proyecto Healthflow, así como la justificación de las seis preguntas de negocio implementadas en `business_questions.sql`.

El objetivo del QA es garantizar que:

1. Los modelos Gold materializan correctamente los datos desde las capas inferiores.
2. No existen pérdidas de registros inesperadas en los JOINs.
3. Las columnas calculadas son correctas y consistentes.
4. Las queries de negocio responden de forma precisa y reproducible a las preguntas planteadas.

---

## 2. Procedimiento de QA

### 2.1 Revisión Estructural (Static Analysis)

Se revisó el código fuente de cada modelo SQL para verificar:

| Check | `gold_financial_analytics` | `gold_medical_performance` |
|-------|---------------------------|---------------------------|
| Materialización correcta (`table`) | ✅ | ✅ |
| Referencias dbt correctas (`{{ ref(...) }}`) | ✅ | ✅ |
| Alias de tablas coherentes | ✅ (`b`, `c`, `doc`, `dt`) | ✅ (`a`, `d`) |
| Columnas derivadas documentadas | ✅ (`revenue_source`) | ✅ (status para filtro) |
| Tipo de JOIN apropiado | ✅ LEFT JOIN | ✅ LEFT JOIN |
| Sin cláusula WHERE en el modelo base | ✅ (máxima flexibilidad) | ✅ (máxima flexibilidad) |

**Resultado:** Ambos modelos presentan una estructura correcta y alineada con buenas prácticas dbt.

### 2.2 Verificación de Linaje

Se trazó el linaje completo de cada modelo:

**`gold_financial_analytics`**
```
fact_billing ──────────────────── base del modelo
dim_clinics  ── LEFT JOIN ──────── por clinic_id → clinic_name
dim_doctor   ── LEFT JOIN ──────── por doctor_id → first_name, last_name
dim_date     ── LEFT JOIN ──────── por date_id   → year, month
```

**`gold_medical_performance`**
```
dim_appointments ── base del modelo (ya desnormalizada)
dim_date         ── LEFT JOIN ── por date_id → year, month
```

**Hallazgo relevante:** `gold_medical_performance` no une directamente con `fact_appointments`, sino que parte de `dim_appointments` (dimensión desnormalizada). Esto es válido si la dimensión está correctamente construida en capas upstream, pero introduce **dependencia de calidad en la dimensión**. Se recomienda validar la completitud de `dim_appointments` en la capa Silver.

### 2.3 Validaciones de Datos (Runtime Checks)

Los siguientes tests dbt se recomiendan para ejecutar en CI/CD:

```yaml
# En schema.yml del modelo gold

models:
  - name: gold_financial_analytics
    columns:
      - name: billing_id
        tests:
          - not_null
          - unique
      - name: total_amount
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
      - name: revenue_source
        tests:
          - accepted_values:
              values: ['Insurance', 'Direct']
      - name: clinic_name
        tests:
          - not_null:
              severity: warn   # LEFT JOIN puede producir NULLs
              
  - name: gold_medical_performance
    columns:
      - name: appointment_id
        tests:
          - not_null
          - unique
      - name: status
        tests:
          - not_null
      - name: year
        tests:
          - not_null
```

### 2.4 Checks de Integridad Referencial

```sql
-- Verificar facturas sin clínica asociada (NULL por LEFT JOIN)
SELECT COUNT(*) AS orphan_billings
FROM gold_financial_analytics
WHERE clinic_name IS NULL;
-- Esperado: 0 o muy bajo (<1%)

-- Verificar citas sin fecha asociada
SELECT COUNT(*) AS orphan_appointments
FROM gold_medical_performance
WHERE year IS NULL;
-- Esperado: 0

-- Verificar valores distintos de revenue_source
SELECT revenue_source, COUNT(*) 
FROM gold_financial_analytics 
GROUP BY revenue_source;
-- Esperado: solo 'Insurance' y 'Direct'

-- Verificar rangos de fechas razonables
SELECT MIN(year), MAX(year) FROM gold_financial_analytics;
-- Esperado: años dentro del rango operativo de la clínica
```

### 2.5 Checks de Consistencia entre Modelos

Para las queries que cruzan ambos modelos (BQ-04), se verifica la compatibilidad:

```sql
-- Doctors presentes en billing pero no en appointments
SELECT DISTINCT fa.doctor_name
FROM gold_financial_analytics fa
LEFT JOIN gold_medical_performance mp ON fa.doctor_name = mp.doctor_name
WHERE mp.doctor_name IS NULL;
-- Esperado: vacío o mínimo (indicaría inconsistencias entre modelos)
```

---

## 3. Justificación de las Preguntas de Negocio

### BQ-01 — Citas completas por clínica y mes

**Justificación:** Es el KPI operativo más básico de una red de clínicas. Permite detectar estacionalidad, capacidad ociosa y comparar rendimiento entre centros. La granularidad mensual es el nivel mínimo para toma de decisiones de gestión de recursos.

**Tabla origen:** `gold_medical_performance` filtrada por `status = 'Completed'`.

**Riesgo de calidad:** Los valores de `status` pueden variar en idioma/formato entre entornos. La query usa `LOWER()` para mayor robustez.

---

### BQ-02 — Ingresos totales por clínica

**Justificación:** La pregunta más directa de P&L (Profit & Loss) por centro. Necesaria para cualquier análisis de rentabilidad, benchmarking entre clínicas y asignación de presupuestos. Incluye el desglose entre total, seguro y copago para tener una foto completa de la estructura de ingresos.

**Tabla origen:** `gold_financial_analytics` agregada por `clinic_name`.

**Riesgo de calidad:** Si `clinic_name` es NULL (facturas huérfanas), aparecería una fila NULL en el resultado. Se recomienda filtrar o añadir `COALESCE(clinic_name, 'Sin Clínica')`.

---

### BQ-03 — Proporción de ingresos cubiertos por seguro

**Justificación:** Métrica crítica de riesgo financiero. Una dependencia excesiva de aseguradoras (>70%) hace a la clínica vulnerable a renegociaciones. La columna `revenue_source` del modelo Gold fue diseñada específicamente para facilitar esta segmentación. El uso de `NULLIF` previene errores de división por cero.

**Tabla origen:** `gold_financial_analytics` con cálculo de ratio.

**Insight adicional:** Se incluye recuento de facturas por tipo de fuente para contextualizar el porcentaje con el volumen real.

---

### BQ-04 — Coste medio por tratamiento según especialidad

**Justificación:** Clave para la tarificación de servicios y negociación con aseguradoras. Permite identificar qué especialidades son más rentables per capita y cuáles tienen mayor variabilidad de coste (cirugías vs consultas rutinarias).

**Complejidad técnica:** Esta pregunta requiere cruzar `gold_financial_analytics` (datos financieros) con `gold_medical_performance` (datos clínicos, especialidad). El JOIN se realiza por `doctor_name + clinic_name + year + month`, lo que puede producir duplicados si un doctor tiene múltiples citas en el mismo mes. La query filtra por `status = 'Completed'` para excluir citas canceladas que no generarían factura real.

**Limitación documentada:** Si el JOIN doctor_name es ambiguo (dos doctores con el mismo nombre), los resultados pueden no ser precisos. Idealmente se usaría un `doctor_id` compartido entre modelos.

---

### BQ-05 — Doctores que generan más ingresos

**Justificación:** Información clave para RRHH y dirección médica. Identifica los "key performers" económicos, apoya decisiones de retención de talento y permite analizar si el rendimiento está concentrado en pocos individuos (riesgo de dependencia).

**Tabla origen:** `gold_financial_analytics` con `GROUP BY doctor_name, clinic_name`.

**Diseño:** Se incluye `clinic_name` en el GROUP BY para distinguir si un doctor trabaja en varias clínicas con rendimientos diferentes. Se limita a TOP 10 para uso ejecutivo, aunque puede quitarse el LIMIT para análisis completo.

---

### BQ-06 — Cinco tratamientos más frecuentes

**Justificación:** Fundamental para la planificación de inventario médico, formación del personal y definición de la cartera de servicios. Los tratamientos más frecuentes son también los que más impactan en la experiencia del paciente.

**Limitación arquitectónica documentada:** El modelo `gold_medical_performance` expone `appointment_type` (tipo de cita), que es una aproximación al concepto de tratamiento. Para el análisis granular de tratamientos clínicos específicos (fármaco administrado, tipo de cirugía, prueba diagnóstica) se requeriría la tabla `fact_appointments_treatments` JOIN `dim_treatment`, que no está disponible en los modelos Gold actuales. Esta limitación queda explícitamente documentada en el código SQL con una nota técnica y la query alternativa correspondiente.

La query incluye `completion_rate_pct` como dato adicional de valor para detectar tipos de cita con mayor tasa de abandono.

---

## 4. Hallazgos y Recomendaciones

### Hallazgos Positivos ✅
- Ambos modelos usan LEFT JOINs correctamente, evitando pérdida de hechos.
- La columna `revenue_source` en `gold_financial_analytics` es un buen ejemplo de enriquecimiento de datos en la capa Gold para facilitar el consumo downstream.
- Los modelos mantienen granularidad a nivel de registro (sin pre-agregación), lo que maximiza la flexibilidad analítica.

### Mejoras Recomendadas ⚠️

| Prioridad | Recomendación |
|-----------|---------------|
| Alta | Añadir `doctor_id` como clave de JOIN entre modelos Gold para mayor precisión en BQ-04 |
| Alta | Implementar tests dbt de `not_null` y `unique` en columnas clave antes de producción |
| Media | Crear un modelo `gold_appointments_treatments` que una `fact_appointments_treatments` + `dim_treatment` para resolver BQ-06 con datos reales de tratamientos |
| Media | Añadir columna `clinic_city` a `gold_financial_analytics` (disponible en `gold_medical_performance`) para análisis geográfico financiero |
| Baja | Estandarizar el campo `status` en toda la pipeline (definir valores canónicos: 'Completed', 'Cancelled', 'No-show') |
| Baja | Añadir marca temporal `_updated_at` a los modelos Gold para detectar retrasos en el pipeline |

---

## 5. Conclusión

Los modelos `gold_financial_analytics` y `gold_medical_performance` están bien estructurados y responden a las necesidades analíticas del negocio. Las seis preguntas de negocio implementadas cubren el espectro completo de análisis clínico-financiero, desde KPIs operativos básicos (BQ-01) hasta métricas de rentabilidad por especialidad (BQ-04).

Las principales limitaciones identificadas son de naturaleza arquitectónica (ausencia de `fact_appointments_treatments` en Gold) y están debidamente documentadas en el código con alternativas. Se recomienda implementar los tests dbt propuestos antes del despliegue en producción.

**Estado del QA:** ✅ APROBADO CON RECOMENDACIONES

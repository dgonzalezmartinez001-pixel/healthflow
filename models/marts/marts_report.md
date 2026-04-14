# Informe de Capa Marts (Modelo Dimensional) — HealthFlow Analytics

**Autor:** Miembro 3
**Configuración:** Capa *Silver* / `marts` en dbt (DuckDB)
**Objetivo:** Construcción de un modelo dimensional (Kimball) optimizado para análisis de negocio a partir del modelo relacional 3NF.

---

## 1. Resumen Ejecutivo

Se ha completado la implementación de la **capa dimensional (Marts)**, transformando el modelo relacional en un esquema analítico basado en principios Kimball.

El diseño se ha centrado en habilitar análisis tanto financieros como operativos mediante la construcción de un **star schema con doble tabla de hechos**, permitiendo capturar correctamente las distintas granularidades del negocio.

El modelo resultante permite responder todas las preguntas de negocio planteadas y se encuentra preparado para su consumo en la capa Gold y posterior explotación en PySpark.

---

## 2. Enfoque de Diseño

### 2.1 Decisión clave: doble tabla de hechos

Durante el análisis del dominio se identificaron dos niveles de granularidad:

* **Nivel financiero** → facturación (billing)
* **Nivel operativo** → tratamientos realizados en citas

Por ello, se optó por un modelo con dos tablas de hechos:

1. `fact_billing`
2. `fact_appointment_treatments`

Esta decisión permite evitar pérdida de información y soportar tanto métricas económicas como clínicas.

---

## 3. Implementación del Modelo Dimensional

Se han desarrollado los modelos en la ruta `models/marts/` materializados como tablas para optimizar el rendimiento analítico.

### 3.1 Fact Table: fact_billing

* **Grain:** 1 fila = 1 factura (`billing_id`)
* **Propósito:** Análisis financiero

Incluye métricas como:

* `total_amount`
* `insurance_amount`
* `copay_amount`
* `payment_method`

**Decisión clave:**
Se utiliza `payment_method` para distinguir ingresos provenientes de aseguradoras vs pago directo.

---

### 3.2 Fact Table: fact_appointment_treatments

* **Grain:** 1 fila = 1 tratamiento en una cita
* **Propósito:** Análisis operativo y clínico

Incluye:

* `actual_price`

**Decisión crítica:**
Se utiliza `actual_price` en lugar de `base_price`, ya que refleja el ingreso real y no el teórico del catálogo.

---

## 4. Construcción de Dimensiones

Se han construido dimensiones desnormalizadas siguiendo el enfoque Kimball.

### 4.1 dim_appointments (dimensión enriquecida)

Se ha creado una dimensión central enriquecida mediante JOINs:

* `int_appointments`
* `int_clinics`
* `int_doctors`

Esto permite incluir atributos como:

* ciudad
* especialidad
* nombre del doctor

**Beneficio:**
Reduce la complejidad de las consultas analíticas.

---

### 4.2 Otras dimensiones

* `dim_patient`
* `dim_doctor`
* `dim_clinic`
* `dim_treatment`
* `dim_date`

Estas dimensiones proporcionan el contexto necesario para segmentar y analizar las métricas.

---

## 5. Relación entre tablas (Star Schema)

El modelo sigue un esquema estrella con dos hechos conectados a través de la clave:

* `appointment_id`

Esto permite:

* Integrar análisis financiero y clínico
* Cruzar información de tratamientos con ingresos

---

## 6. Decisiones de Diseño Relevantes

### Uso de `billing` como fact financiera

Se ha seleccionado `billing` como fuente principal de métricas económicas, ya que representa eventos reales de ingreso (excluyendo citas canceladas o no presentadas).

---

### Uso de `appointment_treatments` para granularidad fina

Permite capturar múltiples tratamientos por cita, evitando pérdida de detalle.

---

### Denormalización controlada

Se han enriquecido dimensiones mediante JOINs, evitando duplicidad lógica pero optimizando el rendimiento.

---

## 7. Validación del Modelo

Se verificó que el modelo permite responder correctamente a:

* Ingresos por clínica y mes
* Proporción seguro vs pago directo
* Top tratamientos
* Coste medio por tratamiento
* Actividad por doctor

---

## 8. Preparación para Capa Gold

El modelo dimensional sirve como base para la capa Gold, donde se construirán agregaciones optimizadas para consumo en PySpark.

---

## 9. Handoff al análisis (PySpark)

El modelo está listo para su explotación analítica.

Recomendaciones:

* Utilizar `fact_billing` para KPIs financieros
* Utilizar `fact_appointment_treatments` para análisis clínicos
* Cruzar ambas mediante `appointment_id`

---

## 10. Conclusión

Se ha construido un modelo dimensional robusto y escalable que permite representar correctamente la complejidad del negocio de HealthFlow.

La separación en dos tablas de hechos ha sido clave para capturar distintas granularidades sin comprometer la integridad analítica.

El sistema queda preparado para análisis avanzados y generación de métricas en la capa Gold.

---

Modelo dimensional completado y listo para explotación analítica.

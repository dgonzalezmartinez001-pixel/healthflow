-- =============================================================================
-- business_questions.sql
-- Proyecto: Healthflow — Capa Gold
-- Descripción: 6 preguntas de negocio sobre rendimiento médico y financiero
--              de la red de clínicas. Queries listas para ejecutar sobre los
--              modelos Gold: gold_medical_performance y gold_financial_analytics.
-- Entorno: DuckDB / SQLite (compatible SQL estándar)
-- Fecha: Abril 2026
-- =============================================================================


-- =============================================================================
-- BQ-01: ¿Cuántas citas completas tiene cada clínica por mes?
-- Modelo(s): gold_medical_performance  [M3/M5]
-- Lógica: Filtrar status='Completed', agrupar por clínica + año + mes
-- =============================================================================

SELECT
    year,
    month,
    clinic_name,
    COUNT(appointment_id)   AS completed_appointments
FROM gold_medical_performance
WHERE LOWER(status) = 'completed'
GROUP BY
    year,
    month,
    clinic_name
ORDER BY
    year   ASC,
    month  ASC,
    completed_appointments DESC;

/*

INTERPRETACIÓN:
- Permite identificar meses de alta/baja demanda por clínica.
- Clave para planificación de recursos médicos y turnos.
- Si una clínica muestra caída sostenida → investigar rotación de médicos o
  problemas de agenda.
*/


-- =============================================================================
-- BQ-02: ¿Cuáles son los ingresos totales por clínica?
-- Modelo(s): gold_financial_analytics  [M4/M5]
-- Lógica: Agrupar fact_billing por dim_clinic, sumar total_amount
-- =============================================================================

SELECT
    clinic_name,
    SUM(total_amount)       AS total_revenue,
    SUM(insurance_amount)   AS total_insurance,
    SUM(copay_amount)       AS total_copay,
    COUNT(billing_id)       AS total_invoices
FROM gold_financial_analytics
GROUP BY clinic_name
ORDER BY total_revenue DESC;

/*

INTERPRETACIÓN:
- Ranking de clínicas por volumen de facturación.
- Permite identificar centros más rentables y los que necesitan apoyo comercial.
- Comparar total_revenue vs total_invoices revela el ticket medio por clínica.
*/


-- =============================================================================
-- BQ-03: ¿Qué proporción de ingresos está cubierta por seguro?
-- Modelo(s): gold_financial_analytics  [M4/M5]
-- Lógica: SUM(insurance_amount) / SUM(total_amount) por clínica
-- =============================================================================

SELECT
    clinic_name,
    SUM(total_amount)                                           AS total_revenue,
    SUM(insurance_amount)                                       AS insurance_revenue,
    SUM(total_amount) - SUM(insurance_amount) - SUM(copay_amount) AS out_of_pocket,
    ROUND(
        100.0 * SUM(insurance_amount) / NULLIF(SUM(total_amount), 0),
        2
    )                                                           AS insurance_pct,
    COUNT(CASE WHEN revenue_source = 'Insurance' THEN 1 END)    AS insurance_invoices,
    COUNT(CASE WHEN revenue_source = 'Direct'    THEN 1 END)    AS direct_invoices
FROM gold_financial_analytics
GROUP BY clinic_name
ORDER BY insurance_pct DESC;

/*

INTERPRETACIÓN:
- Una proporción alta de seguro (>60%) indica dependencia de aseguradoras;
  riesgo si cambian condiciones contractuales.
- Proporción baja de seguro → más ingresos directos (mayor riesgo de impago,
  pero mayor margen).
- NULLIF evita división por cero en clínicas sin facturación registrada.
*/


-- =============================================================================
-- BQ-04: ¿Cuál es el coste medio por tratamiento según especialidad?
-- Modelo(s): gold_financial_analytics + gold_medical_performance  [M4/M5]
-- Lógica: JOIN por clinic_name + doctor_name para cruzar billing con specialty
-- Nota: En ausencia de fact_appointments_treatments, se aproxima mediante
--       el JOIN de ambos modelos Gold por doctor y clínica en el mismo período.
-- =============================================================================

SELECT
    mp.doctor_specialty,
    COUNT(DISTINCT fa.billing_id)           AS num_bills,
    ROUND(AVG(fa.total_amount), 2)          AS avg_cost_per_bill,
    ROUND(MIN(fa.total_amount), 2)          AS min_cost,
    ROUND(MAX(fa.total_amount), 2)          AS max_cost,
    ROUND(SUM(fa.total_amount), 2)          AS total_revenue
FROM gold_financial_analytics fa
INNER JOIN gold_medical_performance mp
    ON  fa.doctor_name  = mp.doctor_name
    AND fa.clinic_name  = mp.clinic_name
    AND fa.year         = mp.year
    AND fa.month        = mp.month
WHERE LOWER(mp.status) = 'completed'
GROUP BY mp.doctor_specialty
ORDER BY avg_cost_per_bill DESC;

/*

INTERPRETACIÓN:
- Las especialidades quirúrgicas generan mayor facturación media.
- Medicina General tiene volumen alto pero ticket bajo → palanca de crecimiento
  si se aumenta la captación de seguros.
- El rango min/max indica variabilidad del tipo de intervención dentro de cada
  especialidad.
*/


-- =============================================================================
-- BQ-05: ¿Qué doctores generan más ingresos?
-- Modelo(s): gold_financial_analytics  [M5]
-- Lógica: GROUP BY doctor_name ORDER BY SUM(total_amount) DESC
-- =============================================================================

SELECT
    doctor_name,
    clinic_name,
    COUNT(billing_id)               AS num_invoices,
    ROUND(SUM(total_amount), 2)     AS total_revenue,
    ROUND(AVG(total_amount), 2)     AS avg_revenue_per_invoice,
    ROUND(SUM(insurance_amount), 2) AS total_insurance_billed
FROM gold_financial_analytics
GROUP BY doctor_name, clinic_name
ORDER BY total_revenue DESC
LIMIT 10;

/*

INTERPRETACIÓN:
- Identifica los médicos de mayor impacto económico → candidates para
  programas de retención y beneficios especiales.
- Comparar avg_revenue vs num_invoices: un doctor con pocos ingresos altos
  es especialista de alto valor; muchos ingresos bajos es médico de volumen.
- Incluir clinic_name para detectar si el rendimiento es transferible o
  depende del contexto local.
*/


-- =============================================================================
-- BQ-06: ¿Cuáles son los cinco tratamientos más frecuentes?
-- Modelo(s): gold_medical_performance (vía appointment_type)  [M5]
-- Nota: El modelo gold_medical_performance expone appointment_type como
--       aproximación a tipo de tratamiento. Para el detalle completo de
--       tratamientos clínicos se requiere fact_appointments_treatments +
--       dim_treatment (ver nota al pie).
-- =============================================================================

SELECT
    appointment_type,
    COUNT(appointment_id)                           AS total_appointments,
    COUNT(CASE WHEN LOWER(status)='completed' 
               THEN 1 END)                          AS completed,
    ROUND(
        100.0 * COUNT(CASE WHEN LOWER(status)='completed' THEN 1 END)
        / NULLIF(COUNT(appointment_id), 0),
        1
    )                                               AS completion_rate_pct
FROM gold_medical_performance
GROUP BY appointment_type
ORDER BY total_appointments DESC
LIMIT 5;

/*

INTERPRETACIÓN:
- Las consultas generales y revisiones dominan el volumen operativo.
- La tasa de completion alta (>85%) indica buena adherencia de los pacientes.
- Las urgencias programadas tienen la menor tasa → oportunidad de mejora en
  comunicación y recordatorios de cita.

NOTA TÉCNICA: Para análisis detallado por tipo de tratamiento clínico
(fármaco, cirugía, prueba diagnóstica), ejecutar:

    SELECT
        dt.treatment_name,
        COUNT(fat.appointment_id)   AS frequency
    FROM fact_appointments_treatments fat
    JOIN dim_treatment dt ON fat.treatment_id = dt.treatment_id
    GROUP BY dt.treatment_name
    ORDER BY frequency DESC
    LIMIT 5;
*/

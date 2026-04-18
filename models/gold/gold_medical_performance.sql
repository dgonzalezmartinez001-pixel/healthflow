-- gold_medical_performance.sql
{{ config(materialized='table') }}

SELECT
    -- Dimensiones temporales
    d.date_id,
    d.year,
    d.month,
    -- Dimensiones de Clínica
    a.clinic_name,
    a.clinic_city,
    -- Dimensiones de Doctor
    a.doctor_name,
    a.doctor_specialty,
    -- Métricas
    a.appointment_id,
    a.status, -- Para filtrar por 'Completed'
    a.appointment_type,
    -- Auditoría
    now() as _updated_at
FROM {{ ref('dim_appointments') }} a
LEFT JOIN {{ ref('dim_date') }} d ON a.date_id = d.date_id

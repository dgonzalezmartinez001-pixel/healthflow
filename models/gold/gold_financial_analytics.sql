-- gold_financial_analytics.sql
{{ config(materialized='table') }}

SELECT
    -- Dimensiones
    dt.year,
    dt.month,
    c.clinic_name,
    c.city as clinic_city,
    doc.doctor_id,
    doc.first_name || ' ' || doc.last_name as doctor_name,
    -- Métricas Financieras
    b.billing_id,
    b.total_amount,
    b.insurance_amount,
    b.copay_amount,
    b.payment_method,
    -- Flag para facilitar proporción en PySpark
    CASE WHEN b.insurance_amount > 0 THEN 'Insurance' ELSE 'Direct' END as revenue_source,
    -- Auditoría
    now() as _updated_at
FROM {{ ref('fact_billing') }} b
LEFT JOIN {{ ref('dim_clinic') }} c ON b.clinic_id = c.clinic_id
LEFT JOIN {{ ref('dim_doctor') }} doc ON b.doctor_id = doc.doctor_id
LEFT JOIN {{ ref('dim_date') }} dt ON b.date_id = dt.date_id

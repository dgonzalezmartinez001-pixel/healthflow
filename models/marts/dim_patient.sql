{{ config(materialized='table') }}

select
    patient_id,
    first_name || ' ' || last_name as full_name,
    gender,
    birth_date,
    -- Cálculo de edad simplificado
    date_diff('year', birth_date, current_date) as age,
    city,
    insurance_company,
    registration_date
from {{ ref('int_patients') }}
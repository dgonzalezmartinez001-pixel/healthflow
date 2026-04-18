{{ config(materialized='table') }}

select
    treatment_id,
    treatment_name,
    specialty,
    base_price,
    duration_minutes
from {{ ref('int_treatments_catalog') }}
where is_active = true

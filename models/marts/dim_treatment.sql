{{ config(materialized='table') }}

select
    treatment_id,
    treatment_name,
    specialty,
    base_price
from {{ ref('int_treatments') }}
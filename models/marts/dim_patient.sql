{{ config(materialized='table') }}

select distinct
    appointment_date as date_id,
    extract(year from appointment_date) as year,
    extract(month from appointment_date) as month
from {{ ref('int_appointments') }}
{{ config(materialized='table') }}

select
    at.appointment_id,
    at.treatment_id,
    a.patient_id,
    a.doctor_id,
    a.clinic_id,
    cast(a.appointment_date as date) as date_id,
    at.actual_price
from {{ ref('int_appointment_treatments') }} at
left join {{ ref('int_appointments') }} a
    on at.appointment_id = a.appointment_id
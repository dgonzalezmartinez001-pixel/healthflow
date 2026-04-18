{{ config(materialized='table') }}

select
    apt_t.appointment_treatment_id,
    apt_t.appointment_id,
    apt_t.treatment_id,
    a.patient_id,
    a.doctor_id,
    a.clinic_id,
    a.scheduled_date as date_id,
    apt_t.actual_price
from {{ ref('int_appointment_treatments') }} apt_t
left join {{ ref('int_appointments') }} a
    on apt_t.appointment_id = a.appointment_id

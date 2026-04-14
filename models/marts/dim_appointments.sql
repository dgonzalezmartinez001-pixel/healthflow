{{ config(materialized='table') }}

select
    a.appointment_id,
    a.appointment_date,
    a.status,
    c.clinic_name,
    c.city,
    d.doctor_name,
    d.specialty
from {{ ref('int_appointments') }} a
left join {{ ref('int_clinics') }} c
    on a.clinic_id = c.clinic_id
left join {{ ref('int_doctors') }} d
    on a.doctor_id = d.doctor_id
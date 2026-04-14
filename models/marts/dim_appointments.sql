{{ config(materialized='table') }}

select
    a.appointment_id,
    a.scheduled_date as date_id,
    a.scheduled_time,
    a.status,
    a.appointment_type,
    c.clinic_name,
    c.city as clinic_city,
    d.first_name || ' ' || d.last_name as doctor_name,
    d.specialty as doctor_specialty
from {{ ref('int_appointments') }} a
left join {{ ref('int_clinics') }} c
    on a.clinic_id = c.clinic_id
left join {{ ref('int_doctors') }} d
    on a.doctor_id = d.doctor_id
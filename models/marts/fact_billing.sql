{{ config(materialized='table') }}

select
    b.billing_id,
    b.appointment_id,
    a.patient_id,
    a.doctor_id,
    a.clinic_id,
    cast(a.appointment_date as date) as date_id,
    b.total_amount,
    b.insurance_amount,
    b.copay_amount,
    b.payment_method
from {{ ref('int_billing') }} b
left join {{ ref('int_appointments') }} a
    on b.appointment_id = a.appointment_id
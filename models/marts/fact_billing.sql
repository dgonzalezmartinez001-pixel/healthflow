{{ config(materialized='table') }}

select
    b.billing_id,
    b.appointment_id,
    a.patient_id,
    a.doctor_id,
    a.clinic_id,
    a.scheduled_date as date_id,
    b.total_amount,
    b.insurance_covered as insurance_amount,
    b.patient_copay as copay_amount,
    b.payment_method
from {{ ref('int_billing') }} b
left join {{ ref('int_appointments') }} a
    on b.appointment_id = a.appointment_id
-- Modelo 3NF: Citas (Entidad Débil / Transaccional)
with source as (
    select * from {{ ref('stg_appointments') }}
),
final as (
    select
        appointment_id,
        patient_id,
        doctor_id,
        clinic_id,
        scheduled_date,
        scheduled_time,
        status,
        appointment_type
    from source
)
select * from final

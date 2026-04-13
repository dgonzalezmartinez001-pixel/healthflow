-- Modelo 3NF: Relación M:N entre Citas y Tratamientos
with source as (
    select * from {{ ref('stg_appointment_treatments') }}
),
final as (
    select
        appointment_treatment_id,
        appointment_id,
        treatment_code,
        actual_price
    from source
)
select * from final

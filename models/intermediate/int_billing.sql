-- Modelo 3NF: Facturación (Entidad Transaccional / Débil)
-- AUDITORÍA 3NF: patient_id se elimina para evitar dependencia transitiva.
-- Sabemos que `billing` depende de `appointment_id`, y `appointment` determina `patient_id`.
with source as (
    select * from {{ ref('stg_billing') }}
),
final as (
    select
        billing_id,
        appointment_id,
        total_amount,
        insurance_covered,
        patient_copay,
        billing_date,
        payment_status,
        payment_method
    from source
)
select * from final

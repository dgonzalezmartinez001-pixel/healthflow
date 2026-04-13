-- Modelo 3NF: Pacientes (Catálogo / Entidad Fuerte)
-- Pacientes contiene primary_clinic_id como sucursal base,
-- que es independiente de donde tomen sus citas (es 3NF válido).
with source as (
    select * from {{ ref('stg_patients') }}
),
final as (
    select
        patient_id,
        first_name,
        last_name,
        birth_date,
        gender,
        city,
        phone,
        email,
        insurance_company,
        insurance_number,
        registration_date,
        primary_clinic_id
    from source
)
select * from final

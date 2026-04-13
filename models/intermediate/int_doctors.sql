-- Modelo 3NF: Doctores (Catálogo / Entidad Fuerte)
-- Entidad que define al personal médico. Se relaciona con la clínica principal (primary_clinic_id).

with source as (
    select * from {{ ref('stg_doctors') }}
),

final as (
    select
        doctor_id,
        primary_clinic_id, -- FK hacia int_clinics
        first_name,
        last_name,
        specialty,
        contract_type,
        hire_date,
        is_active
    from source
)

select * from final

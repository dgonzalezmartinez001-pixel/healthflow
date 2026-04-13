-- Modelo 3NF: Clínica (Catálogo / Entidad Fuerte)
with source as (
    select * from {{ ref('stg_clinics') }}
),
final as (
    select
        clinic_id,
        clinic_name,
        city,
        director_name,
        opened_date,
        is_active
    from source
)
select * from final

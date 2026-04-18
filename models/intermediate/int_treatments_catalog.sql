-- Modelo 3NF: Catálogo de Tratamientos (Catálogo / Entidad Fuerte)
-- Mantiene la lista oficial de tratamientos disponibles.

with source as (
    select * from {{ ref('stg_treatments_catalog') }}
),

final as (
    select
        treatment_id,
        treatment_name,
        specialty,
        base_price,
        duration_minutes,
        is_active
    from source
)

select * from final

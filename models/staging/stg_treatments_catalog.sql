-- =============================================================
-- Modelo : stg_treatments_catalog
-- Fuente : raw.treatments_catalog
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado del catálogo de tratamientos.
--
-- Problemas resueltos:
--   1. specialty llega con mayúsculas/minúsculas mezcladas
--      igual que en doctors — se normaliza a UPPER.
--   2. base_price llega como texto — se castea a DECIMAL.
--   3. duration_minutes llega como texto — se castea a INTEGER.
-- =============================================================

with source as (

    select * from {{ source('raw', 'treatments_catalog') }}

),

cleaned as (

    select
        -- Identificador del tratamiento
        treatment_code,

        -- Nombre descriptivo
        trim(treatment_name)                    as treatment_name,

        -- Especialidad normalizada a mayúsculas
        -- Problema: 'MEDICINA_GENERAL' vs 'medicina_general'
        upper(trim(specialty))                  as specialty,

        -- Precio base: de texto a decimal con 2 decimales
        cast(base_price as decimal(10, 2))      as base_price,

        -- Duración estimada en minutos: de texto a entero
        cast(duration_minutes as integer)       as duration_minutes,

        -- Estado activo: de texto a booleano
        cast(is_active as boolean)              as is_active

    from source

)

select * from cleaned

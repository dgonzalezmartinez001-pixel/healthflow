-- =============================================================
-- Modelo : stg_clinics
-- Fuente : raw.clinics
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado de la tabla maestra de clínicas.
--          Se descartan address y phone por no ser relevantes
--          para la capa analítica.
-- =============================================================

with source as (

    select * from {{ source('raw', 'clinics') }}

),

cleaned as (

    select
        -- Identificador
        clinic_id,

        -- Nombre de la clínica
        name                            as clinic_name,

        -- Ciudad normalizada en mayúsculas para consistencia
        upper(trim(city))               as city,

        -- Director médico
        trim(director_name)             as director_name,

        -- Fecha de apertura: convertida de texto a DATE
        cast(opened_date as date)       as opened_date,

        -- Estado activo: convertido de texto 'True'/'False' a BOOLEAN
        cast(is_active as boolean)      as is_active

        -- Columnas descartadas:
        -- address → no se usa en analítica
        -- phone   → no se usa en analítica

    from source

)

select * from cleaned

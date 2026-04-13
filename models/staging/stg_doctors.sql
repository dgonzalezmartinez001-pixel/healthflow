-- =============================================================
-- Modelo : stg_doctors
-- Fuente : raw.doctors
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado de la tabla maestra de doctores.
--          El campo specialty llega con mayúsculas/minúsculas
--          mezcladas según la clínica de origen — se normaliza
--          a UPPER para garantizar consistencia en agrupaciones.
-- =============================================================

with source as (

    select * from {{ source('raw', 'doctors') }}

),

cleaned as (

    select
        -- Identificador
        doctor_id,

        -- Nombre completo separado en dos campos
        trim(first_name)                        as first_name,
        trim(last_name)                         as last_name,

        -- Especialidad normalizada a mayúsculas
        -- Problema detectado: 'pediatria', 'PEDIATRIA', 'Pediatria'
        -- son el mismo valor — upper() los unifica
        upper(trim(specialty))                  as specialty,

        -- Clínica principal donde trabaja habitualmente
        primary_clinic_id,

        -- Tipo de contrato normalizado a minúsculas
        -- Valores: 'employee', 'contractor'
        lower(trim(contract_type))              as contract_type,

        -- Fecha de contratación: de texto a DATE
        cast(hire_date as date)                 as hire_date,

        -- Estado activo: de texto 'True'/'False' a BOOLEAN
        cast(is_active as boolean)              as is_active

    from source

)

select * from cleaned

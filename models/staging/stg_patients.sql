-- =============================================================
-- Modelo : stg_patients
-- Fuente : raw.patients
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado de la tabla maestra de pacientes.
--
-- Problemas resueltos:
--   1. birth_date llega en dos formatos según clínica de origen:
--        - ISO:     'YYYY-MM-DD'  (ej: 1972-10-27)
--        - Europeo: 'DD/MM/YYYY'  (ej: 25/11/1966)
--      Se detecta el formato por la presencia de '/' y se
--      convierte a DATE con strptime en cada caso.
--
--   2. insurance_company e insurance_number tienen 2.412 nulos.
--      Esto es esperado: pacientes sin seguro (pago directo).
--      Se conservan los nulos — no son errores de datos.
-- =============================================================

with source as (

    select * from {{ source('raw', 'patients') }}

),

cleaned as (

    select
        -- Identificador
        patient_id,

        -- Nombre completo
        trim(first_name)            as first_name,
        trim(last_name)             as last_name,

        -- Fecha de nacimiento: dos formatos en origen
        -- Si contiene '/' → formato DD/MM/YYYY (europeo)
        -- Si no           → formato YYYY-MM-DD (ISO)
        case
            when birth_date like '%/%'
                then strptime(trim(birth_date), '%d/%m/%Y')::date
            else
                cast(birth_date as date)
        end                         as birth_date,

        -- Género: O/F/M — se conserva el valor original
        trim(gender)                as gender,

        -- Ciudad normalizada
        upper(trim(city))           as city,

        -- Teléfono: se conserva como texto (no es campo analítico)
        trim(phone)                 as phone,

        -- Email en minúsculas para consistencia
        lower(trim(email))          as email,

        -- Seguro médico — puede ser NULL (paciente sin seguro)
        trim(insurance_company)     as insurance_company,
        trim(insurance_number)      as insurance_number,

        -- Fecha de alta en el sistema
        cast(registration_date as date) as registration_date,

        -- Clínica principal asignada
        primary_clinic_id

    from source

)

select * from cleaned

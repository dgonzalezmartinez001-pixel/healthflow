-- =============================================================
-- Modelo : stg_appointments
-- Fuente : raw.appointments
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado del registro de citas.
--
-- Problemas resueltos:
--   1. clinic_id llega con dos formatos según clínica de origen:
--        - Correcto:  'CLIN-004'
--        - Roto:      'C002' (prefijo truncado)
--      Se detecta por longitud y se reconstruye el formato
--      estándar 'CLIN-XXX' extrayendo el número.
--
--   2. Columnas desnormalizadas eliminadas:
--        - doctor_specialty → ya existe en stg_doctors
--        - clinic_city      → ya existe en stg_clinics
--      Mantenerlas aquí sería redundancia y fuente de
--      inconsistencias si los datos maestros cambian.
--
--   3. status normalizado a minúsculas.
--   4. scheduled_date casteado a DATE.
--   5. scheduled_time casteado a TIME.
-- =============================================================

with source as (

    select * from {{ source('raw', 'appointments') }}

),

cleaned as (

    select
        -- Identificador de la cita
        appointment_id,

        -- Claves foráneas
        patient_id,
        doctor_id,

        -- clinic_id: normalización del formato
        -- 'CLIN-004' → se conserva tal cual
        -- 'C002'     → se reconstruye como 'CLIN-002'
        case
            when clinic_id like 'CLIN-%'
                then clinic_id
            else
                'CLIN-' || lpad(regexp_extract(clinic_id, '[0-9]+'), 3, '0')
        end                                     as clinic_id,

        -- Fecha y hora de la cita
        cast(scheduled_date as date)            as scheduled_date,
        cast(scheduled_time as time)            as scheduled_time,

        -- Estado normalizado a minúsculas
        -- Valores: completed, cancelled, scheduled, no_show
        lower(trim(status))                     as status,

        -- Tipo de cita normalizado a minúsculas
        -- Valores: first_visit, review, follow_up
        lower(trim(appointment_type))           as appointment_type

        -- Columnas descartadas por desnormalización:
        -- doctor_specialty → disponible en stg_doctors
        -- clinic_city      → disponible en stg_clinics

    from source

)

select * from cleaned
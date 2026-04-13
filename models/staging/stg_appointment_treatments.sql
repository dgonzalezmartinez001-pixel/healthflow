-- =============================================================
-- Modelo : stg_appointment_treatments
-- Fuente : raw.appointment_treatments
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado de la relación cita-tratamiento.
--          Esta tabla resuelve la relación M:N entre citas y
--          tratamientos (una cita puede tener varios tratamientos)
--
-- Problemas resueltos:
--   1. Columna 'notes' descartada: está vacía en el 100% de
--      los registros (46.466 de 46.466). No aporta información
--      y ocupa espacio innecesario en la capa analítica.
--   2. actual_price casteado de texto a DECIMAL.
--   3. id renombrado a appointment_treatment_id para claridad.
-- =============================================================

with source as (

    select * from {{ source('raw', 'appointment_treatments') }}

),

cleaned as (

    select
        -- Identificador propio de esta línea
        cast(id as integer)                         as appointment_treatment_id,

        -- Claves foráneas a citas y tratamientos
        appointment_id,
        treatment_code,

        -- Precio real facturado en esta cita
        -- Puede diferir del base_price del catálogo según
        -- el tipo de paciente o acuerdo con aseguradora
        cast(actual_price as decimal(10, 2))        as actual_price

        -- Columna descartada:
        -- notes → vacía en el 100% de los registros

    from source

)

select * from cleaned

-- =============================================================
-- Modelo : stg_billing
-- Fuente : raw.billing
-- Autor  : Miembro 1
-- Notas  : Limpieza y tipado de la tabla de facturación.
--
-- Problemas resueltos:
--   1. total_amount, insurance_covered y patient_copay llegan
--      como texto — se castean a DECIMAL(10,2).
--   2. billing_date casteado de texto a DATE.
--   3. payment_status y payment_method normalizados a minúsculas.
--
-- Nota de negocio: solo existen 32.422 registros de billing
-- para 50.000 citas. Las citas sin factura corresponden a
-- citas canceladas o no presentadas (no generan facturación).
-- =============================================================

with source as (

    select * from {{ source('raw', 'billing') }}

),

cleaned as (

    select
        -- Identificador de la factura
        billing_id,

        -- Claves foráneas
        appointment_id,
        patient_id,

        -- Importes: de texto a decimal con 2 decimales
        cast(total_amount as decimal(10, 2))        as total_amount,
        cast(insurance_covered as decimal(10, 2))   as insurance_covered,
        cast(patient_copay as decimal(10, 2))       as patient_copay,

        -- Fecha de facturación
        cast(billing_date as date)                  as billing_date,

        -- Estado del pago normalizado a minúsculas
        -- Valores: paid, pending, overdue, cancelled
        lower(trim(payment_status))                 as payment_status,

        -- Método de pago normalizado a minúsculas
        -- Valores: insurance, direct
        lower(trim(payment_method))                 as payment_method

    from source

)

select * from cleaned
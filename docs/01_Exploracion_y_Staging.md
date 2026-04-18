# Informe de Exploración de Datos — HealthFlow Analytics

**Autor:** Miembro 1  
**Fecha:** Abril 2026  
**Fase:** Ingesta y Staging  
**Herramientas:** DuckDB, dbt 1.11.8, Python

---

## 1. Resumen ejecutivo

Se han cargado y analizado 7 ficheros CSV procedentes del sistema operacional de HealthFlow. El volumen total es de **137.036 filas** distribuidas en 7 tablas. Los datos presentan varios problemas de calidad esperados dado el contexto de integración de múltiples sistemas: inconsistencias de formato, columnas desnormalizadas, valores nulos documentados y claves con formatos rotos. Todos los problemas han sido identificados, documentados y resueltos en la capa staging.

---

## 2. Inventario de datasets

| Dataset | Filas | Columnas | Descripción |
|---|---|---|---|
| `clinics` | 10 | 8 | Tabla maestra de clínicas |
| `doctors` | 80 | 8 | Tabla maestra de doctores |
| `patients` | 8.000 | 12 | Tabla maestra de pacientes |
| `treatments_catalog` | 58 | 6 | Catálogo de tratamientos |
| `appointments` | 50.000 | 10 | Registro de citas |
| `appointment_treatments` | 46.466 | 5 | Relación cita-tratamiento (M:N) |
| `billing` | 32.422 | 9 | Facturación por cita |
| **TOTAL** | **137.036** | | |

---

## 3. Problemas detectados y resolución

### 3.1 `clinics` — Clínicas

**Calidad general:** buena. Tabla pequeña (10 filas), sin nulos, sin duplicados.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| Columnas no analíticas | `address` y `phone` no son relevantes para analítica | Descartadas en `stg_clinics` |
| `opened_date` como texto | Llega como `VARCHAR` en lugar de `DATE` | `CAST(opened_date AS DATE)` |
| `is_active` como texto | Llega como `'True'/'False'` en lugar de `BOOLEAN` | `CAST(is_active AS BOOLEAN)` |
| `city` sin normalizar | Mayúsculas inconsistentes posibles | `UPPER(TRIM(city))` |

**Decisión de diseño:** se descartan `address` y `phone` porque ninguna pregunta de negocio del enunciado las requiere, y añaden peso innecesario a la capa analítica.

---

### 3.2 `doctors` — Doctores

**Calidad general:** buena. 80 filas, sin nulos.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| `specialty` con mayúsculas/minúsculas mezcladas | `'pediatria'`, `'PEDIATRIA'`, `'Pediatria'` representan el mismo valor pero DuckDB las trata como distintas al agrupar | `UPPER(TRIM(specialty))` |
| `contract_type` sin normalizar | Valores `'employee'`, `'contractor'` — potencialmente con variaciones de caso | `LOWER(TRIM(contract_type))` |
| `hire_date` como texto | Llega como `VARCHAR` | `CAST(hire_date AS DATE)` |
| `is_active` como texto | Llega como `'True'/'False'` | `CAST(is_active AS BOOLEAN)` |

**Impacto si no se resuelve:** las agregaciones por especialidad (`GROUP BY specialty`) devolverían filas duplicadas — por ejemplo, `'PEDIATRIA'` y `'pediatria'` como grupos separados, distorsionando métricas como ingresos por especialidad.

---

### 3.3 `patients` — Pacientes

**Calidad general:** moderada. Es el dataset con más problemas de calidad.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| `birth_date` en dos formatos | Formato ISO `YYYY-MM-DD` (ej: `1972-10-27`) y formato europeo `DD/MM/YYYY` (ej: `25/11/1966`) mezclados en la misma columna, según la clínica de origen | Detección por presencia de `'/'` + `strptime()` condicional con `CASE WHEN` |
| `insurance_company` nulos | 2.412 filas sin valor (30% del total) | Se conservan como `NULL` — representan pacientes sin seguro (pago directo). No son errores |
| `insurance_number` nulos | 2.412 filas sin valor (mismo subconjunto que `insurance_company`) | Ídem — se conservan como `NULL` |
| `email` sin normalizar | Posibles variaciones de mayúsculas | `LOWER(TRIM(email))` |
| `registration_date` como texto | Llega como `VARCHAR` | `CAST(registration_date AS DATE)` |

**Detalle del problema de `birth_date`:**  
El sistema de origen de algunas clínicas exporta fechas en formato europeo (`DD/MM/YYYY`) mientras que otras usan el estándar ISO (`YYYY-MM-DD`). Un `CAST` directo fallaría en las filas con `/`. La solución implementada detecta el formato por la presencia del carácter `/` y aplica `strptime()` con el patrón correspondiente.

```sql
case
    when birth_date like '%/%'
        then strptime(trim(birth_date), '%d/%m/%Y')::date
    else
        cast(birth_date as date)
end as birth_date
```

**Nota sobre los nulos de seguro:** los 2.412 pacientes sin `insurance_company` ni `insurance_number` son pacientes de pago directo. Esto es coherente con el modelo de negocio descrito en el contexto (40% pago directo). No se imputan ni se rellenan — el nulo es semánticamente correcto.

---

### 3.4 `treatments_catalog` — Catálogo de tratamientos

**Calidad general:** buena. 58 filas, sin nulos.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| `specialty` con mayúsculas/minúsculas mezcladas | `'MEDICINA_GENERAL'` vs `'medicina_general'` — mismo problema que en `doctors` | `UPPER(TRIM(specialty))` |
| `base_price` como texto | Llega como `VARCHAR` | `CAST(base_price AS DECIMAL(10,2))` |
| `duration_minutes` como texto | Llega como `VARCHAR` | `CAST(duration_minutes AS INTEGER)` |
| `is_active` como texto | Llega como `'True'/'False'` | `CAST(is_active AS BOOLEAN)` |

---

### 3.5 `appointments` — Citas

**Calidad general:** moderada. Dataset más grande (50.000 filas). Sin nulos, pero con desnormalización y claves rotas.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| `clinic_id` con formato roto | Dos formatos: `'CLIN-004'` (correcto) y `'C002'` (prefijo truncado). Detectado en registros de clínicas integradas posteriormente | Reconstrucción: `'CLIN-' \|\| lpad(regexp_extract(clinic_id, '[0-9]+'), 3, '0')` |
| Columna `doctor_specialty` desnormalizada | La especialidad del doctor no pertenece a la tabla de citas — ya existe en `doctors` | Descartada en `stg_appointments` |
| Columna `clinic_city` desnormalizada | La ciudad de la clínica no pertenece a la tabla de citas — ya existe en `clinics` | Descartada en `stg_appointments` |
| `scheduled_date` como texto | Llega como `VARCHAR` | `CAST(scheduled_date AS DATE)` |
| `scheduled_time` como texto | Llega como `VARCHAR` | `CAST(scheduled_time AS TIME)` |
| `status` sin normalizar | Posibles variaciones de caso | `LOWER(TRIM(status))` |

**Detalle del problema de `clinic_id`:**  
El formato estándar es `CLIN-XXX` donde `XXX` es un número de 3 dígitos con ceros a la izquierda. Las clínicas integradas más tarde exportan el ID como `CXXX` (sin el prefijo completo). La solución extrae el número con `regexp_extract` y reconstruye el formato estándar.

**Detalle de la desnormalización:**  
Las columnas `doctor_specialty` y `clinic_city` en `appointments` son una violación de la 3NF — dependen de `doctor_id` y `clinic_id` respectivamente, no de `appointment_id`. Mantenerlas en esta tabla generaría redundancia y riesgo de inconsistencias si los datos maestros cambian. Se eliminan aquí; la capa intermediate (Miembro 2) las recuperará vía JOIN cuando sea necesario.

**Observación de negocio:** existen 50.000 citas pero solo 32.422 registros de billing (64,8%). Las citas sin factura corresponden presumiblemente a citas canceladas o no presentadas, que no generan facturación. Esta proporción es coherente con el modelo de negocio.

---

### 3.6 `appointment_treatments` — Relación cita-tratamiento

**Calidad general:** buena. Sin nulos en campos relevantes.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| Columna `notes` vacía al 100% | Los 46.466 registros tienen `notes` vacío — no aporta información | Descartada en `stg_appointment_treatments` |
| `actual_price` como texto | Llega como `VARCHAR` | `CAST(actual_price AS DECIMAL(10,2))` |
| `id` con nombre ambiguo | El nombre `id` no es descriptivo | Renombrado a `appointment_treatment_id` |

**Nota de diseño:** esta tabla es la que resuelve la relación M:N entre `appointments` y `treatments_catalog`. Una cita puede tener varios tratamientos (ej: extracción de sangre + electrocardiograma). Esto es relevante para el Miembro 2 al diseñar el modelo 3NF.

---

### 3.7 `billing` — Facturación

**Calidad general:** buena. Sin nulos, estructura coherente.

| Problema | Detalle | Resolución en staging |
|---|---|---|
| `total_amount` como texto | Llega como `VARCHAR` | `CAST(total_amount AS DECIMAL(10,2))` |
| `insurance_covered` como texto | Llega como `VARCHAR` | `CAST(insurance_covered AS DECIMAL(10,2))` |
| `patient_copay` como texto | Llega como `VARCHAR` | `CAST(patient_copay AS DECIMAL(10,2))` |
| `billing_date` como texto | Llega como `VARCHAR` | `CAST(billing_date AS DATE)` |
| `payment_status` sin normalizar | Valores: `paid`, `pending`, `overdue`, `cancelled` | `LOWER(TRIM(payment_status))` |
| `payment_method` sin normalizar | Valores: `insurance`, `direct` | `LOWER(TRIM(payment_method))` |

---

## 4. Relaciones entre tablas

Las siguientes relaciones fueron identificadas e inferidas del contenido (no todas estaban documentadas explícitamente):

```
clinics         ←── appointments    (clinic_id)
doctors         ←── appointments    (doctor_id)
patients        ←── appointments    (patient_id)
appointments    ←── appointment_treatments  (appointment_id)
treatments_catalog ←── appointment_treatments (treatment_code)
appointments    ←── billing         (appointment_id)
patients        ←── billing         (patient_id)
clinics         ←── patients        (primary_clinic_id)
clinics         ←── doctors         (primary_clinic_id)
```

**Relación implícita detectada:** `billing` contiene `patient_id` además de `appointment_id`. Esto es redundante si `appointments` ya tiene `patient_id`, pero puede ser intencional para facilitar consultas directas de facturación por paciente sin necesidad de JOIN adicional. Se comunica al Miembro 2 para que lo considere en el diseño 3NF.

---

## 5. Tests de calidad ejecutados

Se han definido y ejecutado 14 tests dbt sobre las claves primarias de todos los modelos staging:

| Test | Modelo | Columna | Resultado |
|---|---|---|---|
| `not_null` | `stg_clinics` | `clinic_id` | ✅ PASS |
| `unique` | `stg_clinics` | `clinic_id` | ✅ PASS |
| `not_null` | `stg_doctors` | `doctor_id` | ✅ PASS |
| `unique` | `stg_doctors` | `doctor_id` | ✅ PASS |
| `not_null` | `stg_patients` | `patient_id` | ✅ PASS |
| `unique` | `stg_patients` | `patient_id` | ✅ PASS |
| `not_null` | `stg_treatments_catalog` | `treatment_code` | ✅ PASS |
| `unique` | `stg_treatments_catalog` | `treatment_code` | ✅ PASS |
| `not_null` | `stg_appointments` | `appointment_id` | ✅ PASS |
| `unique` | `stg_appointments` | `appointment_id` | ✅ PASS |
| `not_null` | `stg_appointment_treatments` | `appointment_treatment_id` | ✅ PASS |
| `unique` | `stg_appointment_treatments` | `appointment_treatment_id` | ✅ PASS |
| `not_null` | `stg_billing` | `billing_id` | ✅ PASS |
| `unique` | `stg_billing` | `billing_id` | ✅ PASS |

**Resultado: 14/14 PASS. Todas las claves primarias son únicas y no nulas.**

---

## 6. Comunicación al equipo

### Para el Miembro 2 (modelo 3NF)

- `appointments` tenía `doctor_specialty` y `clinic_city` desnormalizadas — ya eliminadas en staging. El modelo 3NF debe recuperarlas vía JOIN desde `stg_doctors` y `stg_clinics`.
- `billing` tiene `patient_id` redundante (también está en `appointments`). Considerar si mantenerlo o eliminarlo en la capa intermediate.
- `appointment_treatments` es la tabla puente M:N entre citas y tratamientos — fundamental para el diseño 3NF.
- Los 2.412 pacientes sin seguro deben ser tratados como un caso válido (pago directo), no como error.

### Para el Miembro 3 (modelo dimensional)

- La fact table de billing tendrá grain `billing_id` — hay 32.422 registros para 50.000 citas (las citas canceladas/no presentadas no generan factura).
- La columna `actual_price` en `appointment_treatments` puede diferir del `base_price` del catálogo — usar `actual_price` para métricas financieras reales.
- `payment_method` en billing distingue `insurance` vs `direct` — clave para la métrica de proporción seguro/pago directo.

---

## 7. Entregables de la capa staging

| Archivo | Descripción |
|---|---|
| `models/staging/stg_clinics.sql` | Modelo staging de clínicas |
| `models/staging/stg_doctors.sql` | Modelo staging de doctores |
| `models/staging/stg_patients.sql` | Modelo staging de pacientes |
| `models/staging/stg_treatments_catalog.sql` | Modelo staging del catálogo de tratamientos |
| `models/staging/stg_appointments.sql` | Modelo staging de citas |
| `models/staging/stg_appointment_treatments.sql` | Modelo staging de relación cita-tratamiento |
| `models/staging/stg_billing.sql` | Modelo staging de facturación |
| `models/staging/sources.yml` | Declaración de fuentes raw en dbt |
| `models/staging/schema.yml` | Tests de calidad sobre claves primarias |
| `scripts/load_raw.py` | Script de carga de CSVs a DuckDB |
| `exploration_report.md` | Este documento |

---

*Documento generado por Miembro 1 — Pipeline HealthFlow Analytics — Máster Data & Analytics UAM*

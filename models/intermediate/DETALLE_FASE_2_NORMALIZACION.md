# Informe Detallado de la Fase 2: Modelado y Normalización (3NF)

**Proyecto:** HealthFlow Analytics  
**Autor:** Carlos (Miembro 2)  
**Asignación:** Capa de Transformación Relacional (Bronze - Intermediate)

---

## 1. Fundamentos de la Fase de Normalización

El objetivo central de esta fase fue descomponer los datos procedentes de las fuentes desnormalizadas (Staging) para alcanzar la **Tercera Forma Normal (3NF)**. Con esto se asegura que no existan redundancias de datos ni dependencias transitorias, optimizando así la integridad de la base de datos analítica.

---

## 2. Detalle de los Modelos Implementados (7 Modelos)

A continuación se detalla la lógica aplicada en cada uno de los archivos SQL de la carpeta `intermediate/`:

### 2.1 Entidades Fuertes (Catálogos Independientes)

*   **`int_clinics.sql`**: 
    - **Contenido**: Maestro de sedes clínicas.# Informe Detallado de la Fase 2: Modelado y Normalización (3NF)

**Proyecto:** HealthFlow Analytics  
**Autor:** Carlos (Miembro 2)  
**Asignación:** Capa de Transformación Relacional (Bronze - Intermediate)

---

## 1. Fundamentos de la Fase de Normalización

El objetivo central de esta fase fue descomponer los datos procedentes de las fuentes desnormalizadas (Staging) para alcanzar la **Tercera Forma Normal (3NF)**. Con esto se asegura que no existan redundancias de datos ni dependencias transitorias, optimizando así la integridad de la base de datos analítica.

---

## 2. Detalle de los Modelos Implementados (7 Modelos)

A continuación se detalla la lógica aplicada en cada uno de los archivos SQL de la carpeta `intermediate/`:

### 2.1 Entidades Fuertes (Catálogos Independientes)

*   **`int_clinics.sql`**: 
    - **Contenido**: Maestro de sedes clínicas.
    - **Normalización**: Se han seleccionado únicamente atributos atómicos de la clínica: `clinic_id`, `clinic_name`, `city`, `director_name`, `opened_date` e `is_active`. Se eliminaron datos de contacto no estructurados para evitar campos multivaluados.
*   **`int_doctors.sql`**:
    - **Contenido**: Registro de facultativos.
    - **Normalización**: Cumple con la 2NF al estar todos los atributos vinculados inequívocamente a `doctor_id`. La relación con la clínica se gestiona mediante la FK `primary_clinic_id`, eliminando la necesidad de guardar el nombre de la clínica en esta tabla.
*   **`int_patients.sql`**:
    - **Contenido**: Información demográfica del paciente.
    - **Normalización**: Se han separado los datos del seguro (`insurance_company`, `insurance_number`) del registro base del paciente. Esta tabla mantiene el grano a nivel de persona física.
*   **`int_treatments_catalog.sql`**:
    - **Contenido**: Tarifario y servicios médicos.
    - **Normalización**: Define el servicio base independientemente de su ejecución. Atributos: `treatment_code`, `treatment_name`, `base_price` y `duration_minutes`.

### 2.2 Entidades Transaccionales y de Relación (Entidades Débiles)

*   **`int_appointments.sql`**:
    - **Rol**: Evento central de negocio.
    - **Lógica**: Actúa como tabla de unión (JOIN) pura. Contiene las FKs a paciente, doctor y clínica, junto con los atributos del evento: `scheduled_date`, `scheduled_time`, `status` y `type`.
*   **`int_appointment_treatments.sql`**:
    - **Justificación Técnica**: Esta es la **Tabla Puente (Bridge)** que resuelve la relación de muchos a muchos (M:N). Una cita puede tener múltiples tratamientos. Al separar esta lógica de las facturas o de las citas, logramos cumplir con la 1NF (cada registro es un átomo de tratamiento). Se captura aquí el `actual_price` final.
*   **`int_billing.sql`**:
    - **Justificación de la 3NF**: En la fuente original aparecía el `patient_id`. Sin embargo, dado que `billing` depende de `appointment_id`, y la cita ya determina quién es el paciente, el `patient_id` era una **dependencia transitiva**. Se eliminó proactivamente para alcanzar la 3NF pura.

    - **Normalización**: Se han seleccionado únicamente atributos atómicos de la clínica: `clinic_id`, `clinic_name`, `city`, `director_name`, `opened_date` e `is_active`. Se eliminaron datos de contacto no estructurados para evitar campos multivaluados.
*   **`int_doctors.sql`**:
    - **Contenido**: Registro de facultativos.
    - **Normalización**: Cumple con la 2NF al estar todos los atributos vinculados inequívocamente a `doctor_id`. La relación con la clínica se gestiona mediante la FK `primary_clinic_id`, eliminando la necesidad de guardar el nombre de la clínica en esta tabla.
*   **`int_patients.sql`**:
    - **Contenido**: Información demográfica del paciente.
    - **Normalización**: Se han separado los datos del seguro (`insurance_company`, `insurance_number`) del registro base del paciente. Esta tabla mantiene el grano a nivel de persona física.
*   **`int_treatments_catalog.sql`**:
    - **Contenido**: Tarifario y servicios médicos.
    - **Normalización**: Define el servicio base independientemente de su ejecución. Atributos: `treatment_code`, `treatment_name`, `base_price` y `duration_minutes`.

### 2.2 Entidades Transaccionales y de Relación (Entidades Débiles)

*   **`int_appointments.sql`**:
    - **Rol**: Evento central de negocio.
    - **Lógica**: Actúa como tabla de unión (JOIN) pura. Contiene las FKs a paciente, doctor y clínica, junto con los atributos del evento: `scheduled_date`, `scheduled_time`, `status` y `type`.
*   **`int_appointment_treatments.sql`**:
    - **Justificación Técnica**: Esta es la **Tabla Puente (Bridge)** que resuelve la relación de muchos a muchos (M:N). Una cita puede tener múltiples tratamientos. Al separar esta lógica de las facturas o de las citas, logramos cumplir con la 1NF (cada registro es un átomo de tratamiento). Se captura aquí el `actual_price` final.
*   **`int_billing.sql`**:
    - **Justificación de la 3NF**: En la fuente original aparecía el `patient_id`. Sin embargo, dado que `billing` depende de `appointment_id`, y la cita ya determina quién es el paciente, el `patient_id` era una **dependencia transitiva**. Se eliminó proactivamente para alcanzar la 3NF pura.

---

## 3. Justificación de Criterios Aplicados (Defensa Técnica)

### 3.1 Resolución de la Relación M:N
Originalmente, los tratamientos estaban "aplanados" o mezclados en las citas. Se optó por una tabla dedicada (`int_appointment_treatments`) para permitir que una sola cita acumule N tratamientos sin duplicar filas en la tabla de facturación ni en la de citas.

### 3.2 Eliminación de Atributos Redundantes
Se ha eliminado cualquier descripción de clínicas o especialidades de doctor que aparecieran en las tablas de hechos. Estos atributos ahora residen únicamente en sus catálogos originales. En caso de que un doctor cambie de especialidad o una clínica cambie de ciudad, solo hay que actualizar un registro en la tabla maestra, garantizando la integridad referencial en todo el sistema.

---

## 4. Validación de la Estructura

He implementado un total de **14 tests de integridad** (Unique y Not Null) repartidos en todas las claves primarias de estos 7 modelos. Estos tests confirman que la descomposición relacional no ha generado pérdida de datos ni duplicación de eventos durante la normalización.

---
*Este documento detalla el cumplimiento riguroso de la Fase 2 del proyecto HealthFlow Analytics.*

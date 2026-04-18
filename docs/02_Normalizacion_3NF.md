# Informe de Capa Intermediate (Modelo 3NF) — HealthFlow Analytics

**Autor:** Miembro 2  
**Configuración:** Capa *Bronze* / `intermediate` en dbt (DuckDB)  
**Objetivo:** Transformación y modelado estrictamente relacional en Tercera Forma Normal (3NF) para sentar las bases analíticas.

---

## 1. Resumen Ejecutivo

He completado enteramente la etapa correspondiente al **Modelo 3NF**. Basándome en los modelos de *staging* construidos por el Miembro 1, he desarrollado el esqueleto relacional y materializado 7 tablas fuertemente tipadas en la capa de base de datos dedicada. 

Se han corregido errores de casteo heredados desde el origen, y se han aplicado las reglas de normalización al pie de la letra, eliminando dependencias transitivas y atributos que incitaban a la redundancia. El proyecto se encuentra compilando localmente y pasando el 100% de los tests referenciales, **listo para la construcción del esquema dimensional de la capa Silver**.

---

## 2. Auditoría y Hotfix sobre la Capa Staging

Antes de poder materializar el modelo 3NF, me encontré con un *bug* al levantar Dbt.

**Problema Detectado en `stg_appointments`:**
El campo `scheduled_date` contenía datos mixtos con formato de fechas americano (ISO estándar) y europeo (uso de `/`). Si bien el `Miembro 1` resolvió este mismo problema de manera brillante en la tabla de `patients`, este control no se aplicó al script de las citas, lo que rompía la compilación.

**Resolución:**
Accedí a la vista del origen y codifiqué un proceso de casteo condicional empleando `strptime()` para homogeneizar los formatos europeos de forma segura ("07/02/2026") y dejarlos compatibles.

---

## 3. Implementación del Modelo 3NF

Se procedió a construir los siguientes 7 modelos en la ruta `models/intermediate/` configurados como tablas para garantizar la separación por entidad y evitar inconsistencias.

### Entidades Fuertes (Catálogos)
1. **`int_clinics`**: Retiene llaves absolutas, nombres y ubicación de las clínicas operativas.
2. **`int_doctors`**: Aloja el personal. Mantiene la referencia base a `primary_clinic_id` (clínica principal por contrato).
3. **`int_patients`**: Tabla central demográfica de pacientes. 
   - *Nota Importante:* Validé el hallazgo del equipo previo respecto a los valores nulos (30% sin seguro médico). Al representar clientes de tipo "pago directo", procedí a mantener estos registros intactos por ser semánticamente correctos de cara a negocio.
4. **`int_treatments_catalog`**: Lista oficial y estandarizada de servicios médicos disponibles junto con sus duraciones y bases de coste.

### Entidades Transaccionales (Eventos / Operacional)
5. **`int_appointments`**: Tabla central que rige la operatividad. Actúa de enlace entre Doctores, Clínicas y Pacientes.
6. **`int_appointment_treatments`**: Tabla puente (*bridge*) resolviendo limpiamente la relación **M:N** (Muchos a Muchos) originada en las citas, donde un evento pudo acumular múltiples códigos del catálogo de tratamientos a distintos precios de lista.
7. **`int_billing`**: El registro monetario aislado de cada cita.

---

## 4. Decisiones de Diseño sobre Normalización (Criterio 3NF)

Aplicando los conceptos de la Tercera Forma Normal (3NF), ejecuté varias correcciones clave sobre el boceto en sucio de las fuentes operacionales:

- **Se eliminó a los pacientes de la tabla de Facturación:**
  La tabla original enviaba el `patient_id` al lado del `appointment_id` para los eventos comerciales. Dado que una factura depende inequívocamente de la existencia de una cita, y la cita a su vez de un paciente; arrastrar al `patient_id` hasta la factura provocaba una **dependencia transitiva prohibida** en 3NF. He eliminado este campo de `int_billing`. La relación persiste intacta lógicamente gracias a su puente (JOIN) vía `int_appointments`.

- **Mantenimiento de atributos desnormalizados de staging:**
  Atributos como `doctor_specialty` o `clinic_city` que no pertenecían originalmente a la cita tampoco han sido resucitados en esta capa para mantener el diseño impecable.

---

## 5. Aseguramiento de Calidad (Testing)

Se configuró el archivo estructural `schema.yml` mapeando pruebas absolutas de robustez en el nivel de tabla para comprobar la unicidad.

- **Pruebas configuradas:** `unique` y `not_null` en las `Primary Keys` de todas las 7 tablas del modelo 3NF.
- **Resultado:** **14 / 14 TESTS PASADOS**. (0 Fallos). Dbt certifica la integridad del código escrito.

---

## 6. Handoff Recomendado al Miembro 3

¡Capa Base finalizada!  
El testigo del pipeline analítico pasa a responsable el **Miembro 3**, quien ahora debe centrarse en generar la desnormalización para la capa analítica de negocio (Modelo Dimensional o Kimball / Capa Silver).

**Sugerencias del Miembro 2 para la capa Dimensional:**
1. A la hora de construir las Tablas de Dimensiones (`dim_X`), puedes enriquecer `dim_appointments` recuperando con soltura las variables como ciudad o especialidad a través de los JOINs que conectan mi `int_appointments` con `int_clinics` e `int_doctors`.
2. Para la **Fact Table** principal (probablemente de granos a nivel de tarifa/tratamiento de cita), recuerda que la llave de amarre es múltiple. Deberás agrupar utilizando la relación transaccional `int_appointment_treatments`, teniendo en cuenta que una misma `appointment_id` derivó múltiples métricas aditivas (tratamientos facturados).
3. Utiliza la distinción cruzada de mi capa de `int_billing` para levantar KPIs financieros (seguros versus copago), todo vinculándolo mediante la llave de cita.

¡Mucho éxito en la creación del datamart!

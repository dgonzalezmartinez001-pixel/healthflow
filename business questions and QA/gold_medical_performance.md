# 🏥 Modelo: `gold_medical_performance`

**Archivo:** `models/gold/gold_medical_performance.sql`  
**Materialización:** `table`  
**Capa:** Gold  
**Última revisión:** Abril 2026

---

## Descripción

Este modelo Gold expone el **rendimiento operativo médico** de la red de clínicas: citas por clínica, estado de las mismas (completadas, canceladas, etc.), tipo de cita y especialidad del doctor. Sirve de base para análisis de productividad clínica y KPIs de gestión sanitaria.

Cada fila representa **una cita médica individual** con sus dimensiones de contexto temporal, geográfico y profesional.

---

## Linaje (Lineage)

```
dim_appointments  (ya desnormalizada: incluye clinic_name, doctor_name, specialty)
    └── dim_date  (LEFT JOIN por date_id)
            │
            ▼
    gold_medical_performance  ← Este modelo
```

> **Nota de arquitectura:** `dim_appointments` es una dimensión desnormalizada que ya incorpora datos de clínica y doctor. A diferencia de `gold_financial_analytics`, no requiere JOINs adicionales a `dim_clinics` o `dim_doctor`.

---

## Esquema de Columnas

| Columna | Tipo | Fuente | Descripción |
|---------|------|--------|-------------|
| `date_id` | INTEGER | `dim_date.date_id` | Clave de fecha (FK a dim_date) |
| `year` | INTEGER | `dim_date.year` | Año de la cita |
| `month` | INTEGER | `dim_date.month` | Mes de la cita (1-12) |
| `clinic_name` | VARCHAR | `dim_appointments.clinic_name` | Nombre de la clínica |
| `clinic_city` | VARCHAR | `dim_appointments.clinic_city` | Ciudad de la clínica |
| `doctor_name` | VARCHAR | `dim_appointments.doctor_name` | Nombre completo del doctor |
| `doctor_specialty` | VARCHAR | `dim_appointments.doctor_specialty` | Especialidad médica del doctor |
| `appointment_id` | INTEGER | `dim_appointments.appointment_id` | Identificador único de la cita |
| `status` | VARCHAR | `dim_appointments.status` | Estado de la cita (ej: `'Completed'`, `'Cancelled'`) |
| `appointment_type` | VARCHAR | `dim_appointments.appointment_type` | Tipo de cita (ej: presencial, telefónica) |

---

## Lógica de Negocio

### Filtrado por estado
La columna `status` permite filtrar citas completadas para KPIs de productividad:
```sql
WHERE status = 'Completed'
```
Este filtro NO está aplicado en el modelo Gold (se deja sin filtrar para máxima flexibilidad en el consumo downstream). Las queries de negocio aplican el filtro según necesidad.

### Ausencia de métricas agregadas
Al igual que `gold_financial_analytics`, este modelo mantiene granularidad de registro individual. Las agregaciones (COUNT, AVG, etc.) se realizan en las queries de negocio o en los marts.

---

## Uso Recomendado

```sql
-- Citas completadas por clínica y mes
SELECT
    year,
    month,
    clinic_name,
    COUNT(appointment_id) AS completed_appointments
FROM gold_medical_performance
WHERE status = 'Completed'
GROUP BY year, month, clinic_name
ORDER BY year, month, completed_appointments DESC;

-- Top especialidades por volumen de citas
SELECT
    doctor_specialty,
    COUNT(appointment_id) AS total_appointments
FROM gold_medical_performance
WHERE status = 'Completed'
GROUP BY doctor_specialty
ORDER BY total_appointments DESC;
```

---

## Notas y Advertencias

- **Granularidad:** Una fila = una cita (`appointment_id`). No agrupa.
- **Valores de `status`:** Verificar los valores exactos en la fuente (pueden ser en inglés o español según el entorno). Usar `LOWER(status) = 'completed'` para mayor robustez.
- **`dim_appointments` desnormalizada:** Si la dimensión cambia su estructura, este modelo puede necesitar actualización de columnas.
- **Tratamientos:** Para análisis de tratamientos frecuentes, usar `fact_appointments_treatments` JOIN `dim_treatment` (no cubierto en este modelo).

---

## Dependencias dbt

```yaml
depends_on:
  - ref('dim_appointments')
  - ref('dim_date')
```

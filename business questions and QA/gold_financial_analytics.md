# 📊 Modelo: `gold_financial_analytics`

**Archivo:** `models/gold/gold_financial_analytics.sql`  
**Materialización:** `table`  
**Capa:** Gold  
**Última revisión:** Abril 2026

---

## Descripción

Este modelo Gold agrega y consolida la información de **facturación** de toda la red de clínicas, enriquecida con dimensiones de clínica, doctor y fecha. Es la fuente primaria para cualquier análisis financiero de la organización.

Cada fila representa **una transacción de facturación** individual, con todas las dimensiones necesarias para el análisis en herramientas de BI (Metabase, Power BI, Tableau) o en scripts de PySpark/Python.

---

## Linaje (Lineage)

```
fact_billing
    ├── dim_clinics     (LEFT JOIN por clinic_id)
    ├── dim_doctor      (LEFT JOIN por doctor_id)
    └── dim_date        (LEFT JOIN por date_id)
            │
            ▼
    gold_financial_analytics  ← Este modelo
```

---

## Esquema de Columnas

| Columna | Tipo | Fuente | Descripción |
|---------|------|--------|-------------|
| `year` | INTEGER | `dim_date.year` | Año de la transacción |
| `month` | INTEGER | `dim_date.month` | Mes de la transacción (1-12) |
| `clinic_name` | VARCHAR | `dim_clinics.clinic_name` | Nombre de la clínica |
| `doctor_name` | VARCHAR | `dim_doctor.first_name \|\| ' ' \|\| dim_doctor.last_name` | Nombre completo del doctor |
| `billing_id` | INTEGER | `fact_billing.billing_id` | Identificador único de la factura |
| `total_amount` | DECIMAL | `fact_billing.total_amount` | Importe total de la factura |
| `insurance_amount` | DECIMAL | `fact_billing.insurance_amount` | Importe cubierto por el seguro |
| `copay_amount` | DECIMAL | `fact_billing.copay_amount` | Copago del paciente |
| `payment_method` | VARCHAR | `fact_billing.payment_method` | Método de pago utilizado |
| `revenue_source` | VARCHAR | Calculado | `'Insurance'` si insurance_amount > 0, `'Direct'` en caso contrario |

---

## Lógica de Negocio

### Flag `revenue_source`
```sql
CASE WHEN b.insurance_amount > 0 
     THEN 'Insurance' 
     ELSE 'Direct' 
END AS revenue_source
```
Esta columna facilita la segmentación de ingresos en PySpark y herramientas de BI sin necesidad de recalcular la condición cada vez.

### JOINs tipo LEFT JOIN
Se usan LEFT JOINs para garantizar que **ninguna factura se pierda** aunque no tenga doctor, clínica o fecha asociada en las dimensiones (datos huérfanos). Esto es importante en fases tempranas del pipeline donde pueden existir inconsistencias.

---

## Uso Recomendado

```sql
-- Ingresos mensuales por clínica
SELECT
    year,
    month,
    clinic_name,
    SUM(total_amount)      AS total_revenue,
    SUM(insurance_amount)  AS insurance_revenue,
    SUM(copay_amount)      AS copay_revenue
FROM gold_financial_analytics
GROUP BY year, month, clinic_name
ORDER BY year, month, clinic_name;
```

---

## Notas y Advertencias

- **Granularidad:** Una fila = una factura (`billing_id`). No agrupa.
- **NULLs esperados:** Las columnas de dimensión (`clinic_name`, `doctor_name`) pueden ser NULL si el registro de la factura no tiene clave foránea válida.
- **Filtrado por periodo:** Usar siempre `year` y `month` para limitar scans en tablas grandes.
- **PySpark:** La columna `revenue_source` está pensada para facilitar `groupBy('revenue_source')` sin expresiones CASE en el notebook.

---

## Dependencias dbt

```yaml
depends_on:
  - ref('fact_billing')
  - ref('dim_clinics')
  - ref('dim_doctor')
  - ref('dim_date')
```

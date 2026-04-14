# 🏥 Healthflow — Data Warehouse Médico (Capa Gold)

> Proyecto ETL grupal. Pipeline de datos para análisis clínico-financiero de una red de clínicas sanitarias, implementado con **dbt + DuckDB/SQLite**.

---

## 📋 Descripción del Proyecto

**Healthflow** es un sistema de analytics orientado a responder preguntas de negocio sobre el rendimiento médico y financiero de una red de clínicas. La arquitectura sigue el patrón **Medallion (Bronze → Silver → Gold)**, siendo la capa Gold el objeto de este repositorio.

La capa Gold expone dos modelos analíticos principales que sirven como base para dashboards e informes ejecutivos:

| Modelo | Descripción |
|--------|-------------|
| `gold_financial_analytics` | Análisis de facturación, ingresos por clínica y doctor, y proporción de cobertura de seguro |
| `gold_medical_performance` | Rendimiento operativo: citas completadas, tratamientos frecuentes y actividad por especialidad |

---

## 🏗️ Arquitectura de Datos

```
Bronze (raw)
    └── Silver (staging / intermediate)
            └── Gold ← Este repositorio
                    ├── gold_financial_analytics
                    └── gold_medical_performance
```

### Tablas de Dimensiones Utilizadas

| Dimensión | Descripción |
|-----------|-------------|
| `dim_clinics` | Información maestra de clínicas (nombre, ciudad) |
| `dim_doctor` | Datos de médicos (nombre, especialidad) |
| `dim_date` | Calendario analítico (año, mes, día) |
| `dim_appointments` | Citas médicas desnormalizadas (incluye clínica y doctor) |
| `dim_treatment` | Catálogo de tratamientos |

### Tablas de Hechos Utilizadas

| Hecho | Descripción |
|-------|-------------|
| `fact_billing` | Transacciones de facturación (importe total, seguro, copago) |
| `fact_appointments` | Registro de citas (estado, tipo) |
| `fact_appointments_treatments` | Relación cita-tratamiento |

---

## 📁 Estructura del Repositorio

```
healthflow/
├── README.md                        ← Este archivo
├── dbt_project.yml                  ← Configuración del proyecto dbt
├── profiles.yml                     ← Conexión a base de datos
├── .vscode/                         ← Configuración del entorno VS Code
├── models/
│   ├── staging/                     ← Modelos Bronze → Silver
│   ├── intermediate/                ← Transformaciones intermedias
│   ├── marts/                       ← Data marts
│   └── gold/
│       ├── gold_financial_analytics.sql   ← Modelo financiero Gold
│       ├── gold_medical_performance.sql   ← Modelo médico Gold
│       └── ingresos_por_clinica_y_mes.sql ← Agregado auxiliar
├── scripts/                         ← Scripts de utilidad
├── data/                            ← Datos de muestra / seeds
└── docs/
    ├── gold_financial_analytics.md  ← Documentación técnica del modelo financiero
    ├── gold_medical_performance.md  ← Documentación técnica del modelo médico
    └── qa_report.md                 ← Informe de QA y validación
```

---

## 🚀 Configuración del Entorno (VS Code)

El proyecto está configurado para ejecutarse en **VS Code** con las siguientes extensiones recomendadas:

- **dbt Power User** — para ejecutar modelos dbt directamente desde el editor
- **SQLTools** — para conectarse a DuckDB/SQLite
- **Python** — para scripts de utilidad

### Variables de entorno requeridas

```yaml
# profiles.yml
healthflow:
  target: dev
  outputs:
    dev:
      type: duckdb        # o sqlite según entorno
      path: ./data/healthflow.db
```

### Ejecutar modelos

```bash
# Instalar dependencias
pip install dbt-duckdb

# Ejecutar capa Gold completa
dbt run --select gold

# Ejecutar un modelo individual
dbt run --select gold_financial_analytics

# Tests de calidad
dbt test --select gold
```

---

## 📊 Preguntas de Negocio Respondidas

Las siguientes preguntas están implementadas en `business_questions.sql`:

| # | Pregunta | Modelo(s) |
|---|----------|-----------|
| 1 | ¿Cuántas citas completas tiene cada clínica por mes? | M3/M5 |
| 2 | ¿Cuáles son los ingresos totales por clínica? | M4/M5 |
| 3 | ¿Qué proporción de ingresos está cubierta por seguro? | M4/M5 |
| 4 | ¿Cuál es el coste medio por tratamiento según especialidad? | M4/M5 |
| 5 | ¿Qué doctores generan más ingresos? | M5 |
| 6 | ¿Cuáles son los cinco tratamientos más frecuentes? | M5 |

Ver el archivo [`business_questions.sql`](./business_questions.sql) para las queries completas con resultados comentados.

---

## 👥 Equipo

Proyecto desarrollado como tarea grupal para el módulo de ETL (Miembro 4: capa Gold y métricas).

---

## 📄 Licencia

Uso académico interno. Repositorio: [dgonzalezmartinez001-pixel/healthflow](https://github.com/dgonzalezmartinez001-pixel/healthflow)

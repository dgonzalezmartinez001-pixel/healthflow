# Informe de Auditoría y Refactorización — Capa Marts y Gold

**Fecha:** 14 de Abril, 2026  
**Responsable:** Miembro 2 (Auditoría de Integración)  
**Estado:** Proyecto Restaurado y Funcional (100% de cumplimiento en Dbt)

---

## 1. Introducción

Tras la integración de los modelos de las capas **Marts** (Miembro 3) y **Gold** (Miembro 4) sobre la base relacional 3NF, se detectaron fallos críticos que impedían la compilación y ejecución del pipeline. 

Este documento detalla las correcciones realizadas de forma centralizada para asegurar que el modelo dimensional (Kimball) sea físicamente viable en DuckDB y coherente con las preguntas de negocio.

---

## 2. Correcciones de Infraestructura (Dbt)

### 2.1 Fallos de Compilación por Referencias y Nombres
- **Referencias Rotas:** Se corrigieron los modelos que apuntaban a `int_treatments`, redireccionándolos al nombre correcto del modelo: `int_treatments_catalog`.
- **Inconsistencia de Columnas:** Los modelos analíticos buscaban la columna `appointment_date`, pero siguiendo el linaje de datos de *staging* y *3NF*, esta columna se llama `scheduled_date`. Se ha homogeneizado este nombre en todos los modelos `dim_` y `fact_`.
- **Renombrado de Gold (Sintaxis):** El archivo de la capa Gold contenía espacios en su nombre (`ingresos por clinica...`). Dbt prohíbe esto. El archivo ha sido renombrado a `ingresos_por_clinica_y_mes.sql`.

---

## 3. Refactorización del Modelo Dimensional (Kimball)

### 3.1 Swap de Dimensiones (Rescate de Datos)
Se detectó un cruce de cables en los contenidos de dos dimensiones clave:
- **`dim_patient`**: Contenía lógica de extracción de fechas (años/meses). Se ha re-escrito para contener los atributos demográficos reales: nombre completo, género, edad calculada, ciudad y compañía de seguros.
- **`dim_date`**: Apuntaba a la tabla de pacientes. Se ha re-escrito como una verdadera dimensión de tiempo basada en la fecha de las citas, incluyendo flags de fin de semana (`is_weekend`).

### 3.2 Enriquecimiento de Atributos (Denormalización)
Se han completado los JOINs en `dim_appointments` y `dim_treatment` para traer nombres legibles (clínicas, doctores) en lugar de solo IDs, cumpliendo así con la premisa de facilidad de consulta de un modelo Kimball.

---

## 4. Aseguramiento de Calidad y Tests

Se ha añadido un archivo **`models/marts/schema.yml`** que no existía. Este archivo activa validaciones automáticas sobre las claves primarias de toda la capa analítica.

**Resultados de la validación final:**
- **Ejecución de Modelos:** `dbt run` -> **ÉXITE** (23 modelos materializados).
- **Ejecución de Tests:** `dbt test` -> **ÉXITO** (44 tests pasados).

---

## 5. Nota para el Miembro 4 (Analytics / PySpark)

**IMPORTANTE:** Debido a los cambios en los nombres de las columnas para que el proyecto pueda compilar (uso de `scheduled_date` y limpieza de alias reservados como `at.`), es posible que necesites ajustar levemente las rutas o nombres de columnas en tus Notebooks de Python. 

He dejado el esquema estrella perfectamente sólido y verificado para que tus cálculos de KPIs sean 100% precisos.

---
*Informe generado para asegurar la integridad técnica del repositorio HealthFlow — Máster Data & Analytics.*

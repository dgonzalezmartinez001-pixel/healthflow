# 🏥 HealthFlow Analytics

**HealthFlow Analytics** es una plataforma de datos end-to-end diseñada para centralizar y analizar la operativa de una red de clínicas médicas privadas. El proyecto transforma datos crudos y heterogéneos en un modelo dimensional (Kimball) coherente y listo para el análisis avanzado.

## 🚀 Arquitectura del Pipeline

El proyecto sigue una arquitectura de capas diseñada para garantizar la calidad y trazabilidad de los datos:

1.  **Staging (Limpieza)**: Tratamiento de formatos de fecha inconsistentes, normalización de IDs de clínica y limpieza de cadenas.
2.  **Intermediate (Normalización 3NF)**: Descomposición de entidades para eliminar redundancias y dependencias transitivas.
3.  **Marts (Kimball)**: Implementación de un Star Schema con dimensiones enriquecidas y tablas de hechos con niveles de granularidad específicos (Financiero y Clínico).
4.  **Gold (Consumo)**: Vistas y tablas optimizadas para la toma de decisiones y el cálculo de KPIs en PySpark.

## 🛠️ Tecnologías Utilizadas

- **Base de Datos**: [DuckDB](https://duckdb.org/)
- **Transformaciones**: [dbt (data build tool)](https://www.getdbt.com/)
- **Procesamiento de Métricas**: [Apache Spark (PySpark)](https://spark.apache.org/docs/latest/api/python/index.html)
- **Lenguajes**: SQL (DuckDB dialect) y Python 3.12+
- **Gestión de Entorno**: `uv`

## 📋 Ejecución del Proyecto

#### Opción A: Usando `uv` (Recomendado)
```bash
# Sincronizar entorno virtual
uv sync
```

#### Opción B: Usando `pip`
Si no dispones de `uv`, puedes instalar las dependencias directamente:
```bash
pip install dbt-duckdb duckdb pyspark pandas faker numpy
```

### 1. Ingesta de Datos
Genera los datos sintéticos y cárgalos en el esquema `raw` de DuckDB:

```bash
# Dentro de la carpeta healthflow
uv run python scripts/load_raw.py
```

### 2. Transformación dbt
Materializa todas las capas de datos:

```bash
# Compilar y ejecutar modelos
uv run dbt run --profiles-dir .

# Ejecutar tests de calidad
uv run dbt test --profiles-dir .
```

### 3. Cálculo de KPIs (PySpark)
Ejecuta el script final de métricas para obtener los 5 KPIs del negocio:

```bash
uv run python scripts/metrics_final.py
```

## 📊 KPIs de Negocio Implementados

- **Ingresos por Clínica y Mes**: Evolución financiera mensual.
- **Productividad por Doctor**: Citas completadas por cada facultativo.
- **Coste por Especialidad**: Ticket medio por tratamiento según rama médica.
- **Proporción de Seguros**: Desglose de ingresos Aseguradora vs. Pago Directo.
- **Top 5 Tratamientos**: Análisis de volumen de facturación por tipo de servicio.

## 📖 Documentación Técnica

La documentación detallada de cada fase se encuentra en la carpeta `docs/`:

1.  [Exploración y Staging](file:///home/carlos/OneDrive/MABA/ETL/Dagoberto/Trabajo/healthflow/docs/01_Exploracion_y_Staging.md)
2.  [Normalización 3NF](file:///home/carlos/OneDrive/MABA/ETL/Dagoberto/Trabajo/healthflow/docs/02_Normalizacion_3NF.md)
3.  [Modelo Dimensional (Kimball)](file:///home/carlos/OneDrive/MABA/ETL/Dagoberto/Trabajo/healthflow/docs/03_Modelo_Dimensional.md)
4.  [Calidad y QA](file:///home/carlos/OneDrive/MABA/ETL/Dagoberto/Trabajo/healthflow/docs/04_Calidad_y_QA.md)
5.  [Auditoría Final](file:///home/carlos/OneDrive/MABA/ETL/Dagoberto/Trabajo/healthflow/docs/05_Auditoria_Final.md)

---
*Este proyecto forma parte de la actividad evaluable del Máster en Data & Analytics (UAM).*

"""
metrics_final.py — Script de consolidación de KPIs en PySpark para HealthFlow Analytics.

Este script lee de la capa Gold de DuckDB y calcula los 5 KPIs requeridos por el enunciado.
Utiliza DuckDB-Python como puente para cargar los datos en Spark de forma robusta.
"""

from pyspark.sql import SparkSession, Window
from pyspark.sql import functions as F
import duckdb
import os
import pandas as pd

# Configuración de rutas
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(PROJECT_ROOT, "data/healthflow.duckdb")

def main():
    # 1. Inicializar sesión Spark
    spark = SparkSession.builder \
        .appName("HealthFlow-Final-Metrics") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("ERROR")

    print(f"\n[metrics] Conectando a DuckDB en: {DB_PATH}")
    con = duckdb.connect(DB_PATH, read_only=True)

    # Helper para leer tablas de DuckDB a Spark vía Pandas
    def load_table_to_spark(schema, table_name):
        print(f"  > Cargando {schema}.{table_name}...")
        pdf = con.execute(f"SELECT * FROM {schema}.{table_name}").df()
        return spark.createDataFrame(pdf)

    # Cargar modelos necesarios
    try:
        df_finance = load_table_to_spark("main_gold", "gold_financial_analytics")
        df_medical = load_table_to_spark("main_gold", "gold_medical_performance")
        df_treatments = load_table_to_spark("main_marts", "fact_appointment_treatments")
        df_dim_treatment = load_table_to_spark("main_marts", "dim_treatment")
    except Exception as e:
        print(f"\n[ERROR] No se pudieron cargar las tablas: {e}")
        print("Asegúrate de haber ejecutado 'uv run dbt run' exitosamente.")
        return
    finally:
        con.close()

    print("\n" + "="*60)
    print(" KPI 1: Ingresos totales por clínica y mes")
    print("="*60)
    kpi1 = df_finance.groupBy("clinic_name", "year", "month") \
        .agg(F.sum("total_amount").alias("revenue")) \
        .orderBy("year", "month", F.desc("revenue"))
    kpi1.show(truncate=False)

    print("\n" + "="*60)
    print(" KPI 2: Citas completadas por doctor (Top 10)")
    print("="*60)
    kpi2 = df_medical.filter(F.lower(F.col("status")) == 'completed') \
        .groupBy("doctor_name") \
        .agg(F.count("appointment_id").alias("completed_count")) \
        .orderBy(F.desc("completed_count"))
    kpi2.show(10, truncate=False)

    print("\n" + "="*60)
    print(" KPI 3: Coste medio por tratamiento según especialidad")
    print("="*60)
    # Usamos la tabla de hechos de tratamientos para evitar inflación por JOINs financieros
    kpi3 = df_treatments.join(df_medical, "appointment_id") \
        .groupBy("doctor_specialty") \
        .agg(F.avg("actual_price").alias("avg_treatment_cost"),
             F.sum("actual_price").alias("total_specialty_revenue")) \
        .orderBy(F.desc("avg_treatment_cost"))
    kpi3.show(truncate=False)

    print("\n" + "="*60)
    print(" KPI 4: Proporción Seguro vs Pago Directo")
    print("="*60)
    kpi4 = df_finance.groupBy("revenue_source") \
        .agg(F.sum("total_amount").alias("total_revenue"), 
             F.count("billing_id").alias("num_invoices")) \
        .withColumn("pct", F.round(F.col("total_revenue") / F.sum("total_revenue").over(Window.partitionBy()) * 100, 2))
    kpi4.show(truncate=False)

    print("\n" + "="*60)
    print(" KPI 5: Top 5 tratamientos por volumen de facturación")
    print("="*60)
    kpi5 = df_treatments.join(df_dim_treatment, "treatment_code") \
        .groupBy("treatment_name") \
        .agg(F.sum("actual_price").alias("total_billing")) \
        .orderBy(F.desc("total_billing")) \
        .limit(5)
    kpi5.show(truncate=False)

    print("\n[metrics] Proceso finalizado con éxito.\n")
    spark.stop()

if __name__ == "__main__":
    main()

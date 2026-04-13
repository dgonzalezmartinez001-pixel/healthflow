"""
load_raw.py — Carga los CSV de data/raw/ a DuckDB (schema: raw)

Uso:
    uv run python ingestion/load_raw.py

El script es idempotente: si las tablas ya existen, las reemplaza.
"""

import os
import duckdb

RAW_DIR = "data/raw/"
DB_PATH = "data/healthflow.duckdb"

CSV_TABLES = [
    "clinics",
    "doctors",
    "patients",
    "treatments_catalog",
    "appointments",
    "appointment_treatments",
    "billing",
]


def main():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    con = duckdb.connect(DB_PATH)

    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    print(f"[load_raw] Conectado a {DB_PATH}")
    print(f"[load_raw] Cargando tablas en schema 'raw'...\n")

    results = []
    for table in CSV_TABLES:
        csv_path = os.path.join(RAW_DIR, f"{table}.csv")
        if not os.path.exists(csv_path):
            print(f"  ADVERTENCIA: {csv_path} no encontrado, saltando.")
            continue

        # patients.csv escribe nulos reales como \N (na_rep) para distinguirlos de string vacío "".
        # DuckDB necesita nullstr='\N' para interpretar correctamente las tres variantes de null:
        #   \N → NULL real | "" → empty string | "N/A" → literal N/A  (DATA QUALITY: Problema 4)
        if table == "patients":
            read_options = r"header=true, all_varchar=true, nullstr='\N'"
        else:
            read_options = "header=true, all_varchar=true"

        con.execute(f"""
            CREATE OR REPLACE TABLE raw.{table} AS
            SELECT * FROM read_csv_auto('{csv_path}', {read_options})
        """)

        count = con.execute(f"SELECT COUNT(*) FROM raw.{table}").fetchone()[0]
        results.append((table, count))

    print(f"  {'Tabla':<30} {'Filas':>10}")
    print(f"  {'-'*30} {'-'*10}")
    for table, count in results:
        print(f"  {table:<30} {count:>10,}")

    total = sum(c for _, c in results)
    print(f"\n[load_raw] Total: {len(results)} tablas cargadas, {total:,} filas.")

    con.close()


if __name__ == "__main__":
    main()

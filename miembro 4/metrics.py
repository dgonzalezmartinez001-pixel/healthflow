# %%
from pyspark.sql import functions as F

# ingresos por clínica y mes
revenue = df.groupBy("clinic_id", "month") \
    .agg(F.sum("total_amount").alias("revenue"))

# proporción seguro vs directo
payment = df.groupBy("payment_method") \
    .agg(F.sum("total_amount"))



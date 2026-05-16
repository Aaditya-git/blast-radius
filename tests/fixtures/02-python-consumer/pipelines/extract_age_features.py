from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("age_features").getOrCreate()

df = spark.read.table("analytics.dim_customers")

# Extract age-based features
age_features = df.select(
    "customer_id",
    "customer_age",
    (df.customer_age / 10).cast("int").alias("age_decade")
)

age_features.write.mode("overwrite").saveAsTable("analytics.customer_age_features")

# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `extract_age_features.py` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `customer_features_dag.yml` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |

## Notes
- Cross-stack blast radius: dbt compile failure will occur in `dim_customers`, Spark job will fail at runtime when reading `customer_age` from the renamed column, and Airflow DAG config will pass wrong column name to the pipeline
- Python Spark jobs do not fail at compile time — runtime failure may not surface until the DAG next runs

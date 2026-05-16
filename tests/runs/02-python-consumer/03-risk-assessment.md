# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `extract_age_features.py` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `customer_features_dag.yml` | Unknown (no env hints) | Will-go-stale | Unknown (no CODEOWNERS) |

## Notes
- `dim_customers` will fail at dbt compile time — explicit `customer_age` reference in SELECT
- `extract_age_features.py` will fail at Spark runtime (not compile time) — `df.select("customer_age")` and `df.customer_age` will raise `AnalysisException` when the column no longer exists in `dim_customers`
- `customer_features_dag.yml` passes `customer_age` as a config value to the pipeline — the DAG itself won't fail to parse, but the pipeline it triggers will; the config reference will also go stale
- Spark runtime failures are particularly dangerous: no static analysis catches them; the failure surfaces only when the DAG next runs

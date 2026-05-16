# Stage 4 — Migration Plan

## Strategy: coordinated update

3 will-break consumers across 3 stacks, all within the same repo. A coordinated single-PR update minimises the window where the old and new column names diverge. Staging validation required before merge — particularly for the Spark pipeline, which has no compile-time safety net.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_age` → `customer_age_years` in `stg_customers.sql` | Day 0 | Unknown |
| Phase 2 | Update `dim_customers.sql` — replace `customer_age` with `customer_age_years` | Day 0 | Unknown |
| Phase 3 | Update `extract_age_features.py` — replace both `customer_age` references (lines 10, 11) | Day 0 | Unknown |
| Phase 4 | Update `customer_features_dag.yml` — replace `- customer_age` in `feature_columns` | Day 0 | Unknown |
| Phase 5 | Run `dbt compile` to verify no SQL errors | Day 0 | Unknown |
| Phase 6 | Run `extract_age_features.py` in staging to verify Spark job succeeds end-to-end | Day 0 | Unknown |

## Per-consumer migration steps

1. `models/marts/dim_customers.sql` — replace `customer_age` with `customer_age_years` on line 4
2. `pipelines/extract_age_features.py` — replace `"customer_age"` on line 10 and `df.customer_age` on line 11 with `customer_age_years`
3. `dags/customer_features_dag.yml` — replace `- customer_age` on line 11 with `- customer_age_years`

## Rollback triggers

- dbt compile failure after Phase 2
- Spark `AnalysisException` on `customer_age` during Phase 6 staging run
- Airflow DAG parse error after Phase 4
- Any row count or value mismatch in `analytics.customer_age_features` after the migration

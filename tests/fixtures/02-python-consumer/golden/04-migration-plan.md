# Stage 4 — Migration Plan

## Strategy: coordinated update

3 will-break consumers across 3 stacks, all within the same repo. A coordinated update in a single PR is feasible and minimizes the window where the old and new names diverge.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_age` → `customer_age_years` in `stg_customers` | Day 0 | Unknown |
| Phase 2 | Update `dim_customers.sql` to use `customer_age_years` | Day 0 | Unknown |
| Phase 3 | Update `extract_age_features.py` — replace all references to `customer_age` with `customer_age_years` | Day 0 | Unknown |
| Phase 4 | Update `customer_features_dag.yml` `feature_columns` list | Day 0 | Unknown |
| Phase 5 | Run dbt compile + Spark pipeline in staging to verify | Day 0 | Unknown |

## Per-consumer migration steps

1. `dim_customers.sql` — replace `customer_age` with `customer_age_years` in SELECT
2. `extract_age_features.py` — replace `"customer_age"` (line 9) and `df.customer_age` (line 10) with `customer_age_years`
3. `customer_features_dag.yml` — replace `- customer_age` in `feature_columns` with `- customer_age_years`

## Rollback triggers

- dbt compile failure after Phase 2
- Spark pipeline runtime failure reading the new column
- Airflow DAG parse error after Phase 4

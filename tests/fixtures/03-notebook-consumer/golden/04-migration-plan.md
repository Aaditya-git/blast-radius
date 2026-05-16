# Stage 4 — Migration Plan

## Strategy: coordinated update

2 will-break consumers in the same repo. A coordinated single-PR update is the lowest-risk approach.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_age` → `customer_age_years` in `stg_customers` | Day 0 | Unknown |
| Phase 2 | Update `dim_customers.sql` to use `customer_age_years` | Day 0 | Unknown |
| Phase 3 | Update all `customer_age` references in `eda.ipynb` SQL string and DataFrame operations | Day 0 | Unknown |
| Phase 4 | Run dbt compile and execute notebook in staging to verify | Day 0 | Unknown |

## Per-consumer migration steps

1. `dim_customers.sql` — replace `customer_age` with `customer_age_years` in SELECT
2. `eda.ipynb` — replace 4 occurrences of `customer_age` in the SQL string and the DataFrame column reference

## Rollback triggers

- dbt compile failure after Phase 2
- Notebook SQL error at runtime
- Any unexpected null counts or distribution shift in the new column

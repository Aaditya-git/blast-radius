# Stage 4 — Migration Plan

## Strategy: coordinated update

2 will-break consumers in the same repo. A coordinated single-PR update is the lowest-risk approach. Notebook must be executed in staging to confirm the fix before merge — no compile-time check exists for notebook SQL.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_age` → `customer_age_years` in `stg_customers.sql` | Day 0 | Unknown |
| Phase 2 | Update `dim_customers.sql` — replace `customer_age` with `customer_age_years` on line 4 | Day 0 | Unknown |
| Phase 3 | Update `eda.ipynb` — replace all 4 `customer_age` references across the SQL string and plot cell | Day 0 | Unknown |
| Phase 4 | Run `dbt compile` to verify no SQL errors | Day 0 | Unknown |
| Phase 5 | Execute `eda.ipynb` end-to-end in staging to confirm no runtime errors | Day 0 | Unknown |

## Per-consumer migration steps

1. `models/marts/dim_customers.sql` — replace `customer_age` with `customer_age_years` on line 4
2. `notebooks/eda.ipynb` — replace 4 occurrences across 2 cells:
   - sql-query cell: `customer_age` in SELECT (line 9), two CASE branches (lines 11-12), WHERE clause (line 15)
   - plot cell: `df['customer_age']` → `df['customer_age_years']`

## Rollback triggers

- dbt compile failure after Phase 2
- `KeyError` or SQL column-not-found error when executing `eda.ipynb` in Phase 5
- Any unexpected null count or distribution shift in the new column

# Stage 4 — Migration Plan

## Strategy: deprecation window with dual columns

Because all consumers are within the dbt project (no external systems), a deprecation window is feasible and safer than a hard cut.

## Timeline

| Phase | Action | Day |
|---|---|---|
| Phase 1 | Add `customer_age_years` alongside `customer_age` in `stg_customers` | Day 0 |
| Phase 2 | Update `dim_customers` and `fct_orders` to use new column | Day 1 |
| Phase 3 | Update `schema.yml` to add new column docs (keep old marked deprecated) | Day 1 |
| Phase 4 | Run dbt tests; verify both columns return identical values | Day 1 |
| Phase 5 | Mark old column deprecated in schema.yml | Day 2 |
| Phase 6 | Remove `customer_age` from `stg_customers` | Day 14 (after deprecation window) |
| Phase 7 | Remove deprecation docs from `schema.yml` | Day 14 |

## Per-consumer migration steps

1. `dim_customers.sql` — replace 3 references to `customer_age` with `customer_age_years`
2. `fct_orders.sql` — replace 1 reference to `c.customer_age` with `c.customer_age_years`
3. `schema.yml` — replace 2 column name entries

## Rollback triggers

- Any dbt model compile failure after Phase 2
- Any data quality test fails on the new column
- Any stakeholder reports a downstream report showing different numbers

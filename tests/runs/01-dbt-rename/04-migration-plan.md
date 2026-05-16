# Stage 4 — Migration Plan

## Strategy: deprecation window with dual columns

All consumers are within the same dbt project. However, because `dim_customers` derives `age_bucket` from `customer_age` and the column appears in schema docs, a short deprecation window is safer than a hard cut — it allows verification that both columns return identical values before the old one is removed.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Add `customer_age_years` alongside `customer_age` in `stg_customers` | Day 0 | Unknown |
| Phase 2 | Update `dim_customers.sql` — replace 3 references to `customer_age` with `customer_age_years` | Day 1 | Unknown |
| Phase 3 | Update `fct_orders.sql` — replace `c.customer_age` with `c.customer_age_years` | Day 1 | Unknown |
| Phase 4 | Update `schema.yml` — replace both `- name: customer_age` entries | Day 1 | Unknown |
| Phase 5 | Run `dbt compile` + `dbt test`; verify both columns return identical values | Day 1 | Unknown |
| Phase 6 | Remove `customer_age` from `stg_customers` | Day 14 (after deprecation window) | Unknown |
| Phase 7 | Remove any remaining deprecation notes from `schema.yml` | Day 14 | Unknown |

## Per-consumer migration steps

1. `models/marts/dim_customers.sql` — replace `customer_age` with `customer_age_years` on lines 4, 6, and 7 (SELECT + 2x CASE expression)
2. `models/marts/fct_orders.sql` — replace `c.customer_age` with `c.customer_age_years` on line 4
3. `models/marts/schema.yml` — replace `- name: customer_age` on lines 7 and 14

## Rollback triggers

- Any `dbt compile` failure after Phase 2 or Phase 3
- Any `dbt test` failure on the new column
- Row count or value mismatch between `customer_age` and `customer_age_years` during Phase 5
- Any stakeholder reports changed numbers in a downstream report

# Stage 4 — Migration Plan

## Strategy: hard cut

Zero will-break external consumers. Safe to rename the CTE directly.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `base` to `customers_base` in `dim_customers.sql` (2 occurrences) | Day 0 | Unknown |
| Phase 2 | Run dbt compile to verify no errors | Day 0 | Unknown |

## Per-consumer migration steps

1. `dim_customers.sql` — replace `with base as (` with `with customers_base as (` and `select * from base` with `select * from customers_base`

## Rollback triggers

- dbt compile failure (unexpected — this should not occur for a CTE rename)

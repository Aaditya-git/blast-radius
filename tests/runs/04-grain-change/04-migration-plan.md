# Stage 4 — Migration Plan

## Strategy: versioned alias

This is a semantic change with a silent failure mode — a hard cut would corrupt data immediately with no visible error. Introducing `dim_customers_v2` at household grain alongside the existing `dim_customers` (customer grain) gives consumers time to evaluate and migrate safely. The original model is deprecated after a 30-day migration window.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Create `dim_customers_v2` at household grain alongside `dim_customers` | Day 0 | Unknown |
| Phase 2 | Update `schema.yml` to document both models and their grains | Day 1 | Unknown |
| Phase 3 | Audit `fct_orders` — determine if household-grain join is correct or requires redesign | Day 2 | Unknown |
| Phase 4 | Migrate `fct_orders` to reference `dim_customers_v2` if semantics are correct | Day 5 | Unknown |
| Phase 5 | Run data quality checks: compare row counts and aggregations before/after migration | Day 5 | Unknown |
| Phase 6 | Deprecate and remove `dim_customers` | Day 30 | Unknown |

## Per-consumer migration steps

1. `fct_orders.sql` — evaluate join semantics at household grain; update `ref('dim_customers')` to `ref('dim_customers_v2')` after confirming correctness; add a dbt uniqueness test on the join key if applicable

## Rollback triggers

- Any aggregation mismatch between `dim_customers` and `dim_customers_v2` during Phase 5
- Stakeholder report of changed row counts or totals in downstream reports
- Any dbt test failure on uniqueness or row count expectations in Phase 5

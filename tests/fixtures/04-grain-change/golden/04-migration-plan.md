# Stage 4 — Migration Plan

## Strategy: versioned alias

Because this is a semantic change (not a rename), a versioned alias is safer than a hard cut. `dim_customers_v2` is introduced at household grain; `dim_customers` remains at customer grain until all consumers explicitly migrate.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Create `dim_customers_v2` at household grain alongside `dim_customers` | Day 0 | Unknown |
| Phase 2 | Update `schema.yml` to document both models and their grains | Day 1 | Unknown |
| Phase 3 | Audit `fct_orders` — determine if household-grain join is correct or requires redesign | Day 2 | Unknown |
| Phase 4 | Migrate `fct_orders` to reference `dim_customers_v2` if correct | Day 5 | Unknown |
| Phase 5 | Run data quality checks: compare row counts and aggregations before/after | Day 5 | Unknown |
| Phase 6 | Deprecate and remove `dim_customers` | Day 30 | Unknown |

## Per-consumer migration steps

1. `fct_orders.sql` — evaluate join semantics at household grain; update `ref('dim_customers')` to `ref('dim_customers_v2')` after confirming correctness

## Rollback triggers

- Any aggregation mismatch between `dim_customers` and `dim_customers_v2` during Phase 5
- Stakeholder report of changed row counts or totals in downstream reports
- Any dbt test failure on uniqueness or row count expectations

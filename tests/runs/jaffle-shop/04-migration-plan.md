# Stage 4 — Migration Plan

## Strategy: coordinated update

2 in-repo consumers (1 silent-propagation, 1 will-break via MetricFlow), all in the same project, owned by the same team. A coordinated single-PR update is the lowest-risk approach. The MetricFlow semantic model dimension must be updated in the same commit as the column rename — any deployment gap would leave MetricFlow queries broken. `customers.sql` requires no edits (SELECT * handles the rename automatically).

**Note on cross-repo consumers:** this plan covers only in-repo changes. Before merging, audit BI dashboards and any external query selecting `customers.customer_name`. Those are outside dbt compile-time checking.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_name` → `full_name` in `stg_customers.sql` line 17 | Day 0 | @dbt-labs/dx |
| Phase 2 | Update `customers.yml` line 13 — rename column doc entry from `customer_name` to `full_name` | Day 0 | @dbt-labs/dx |
| Phase 3 | Update `customers.yml` line 45 — rename MetricFlow semantic model dimension from `customer_name` to `full_name` | Day 0 | @dbt-labs/dx |
| Phase 4 | Run `dbt compile` to verify no SQL errors | Day 0 | @dbt-labs/dx |
| Phase 5 | Run `dbt parse` or MetricFlow validation to verify the semantic model resolves `full_name` | Day 0 | @dbt-labs/dx |
| Phase 6 | Audit cross-repo consumers: BI dashboards, ML feature pipelines, external queries against `customers.customer_name` | Day 0 | @dbt-labs/dx |

## Per-consumer migration steps

1. `models/staging/stg_customers.sql:17` — change `name as customer_name` → `name as full_name`
2. `models/marts/customers.yml:13` — change `- name: customer_name` (column doc) → `- name: full_name`; update description if it references the old name
3. `models/marts/customers.yml:45` — change `- name: customer_name` (MetricFlow dimension) → `- name: full_name`
4. `models/marts/customers.sql` — **no change needed**; uses `select *` so the renamed column propagates automatically

## Rollback triggers

- `dbt compile` failure after Phase 1
- MetricFlow validation failure after Phase 3
- Any BI dashboard or external query reporting a missing `customer_name` column post-deploy
- Any unexpected null count or data mismatch in `full_name` values vs prior `customer_name` values

# Stage 4 — Migration Plan

## Strategy: coordinated update

2 will-break/silent-propagation consumers, all in the same repo. A coordinated single-PR update is the lowest-risk approach. The MetricFlow semantic model must be updated in the same commit as the column rename — any gap would break MetricFlow queries.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Rename `customer_name` → `full_name` in `stg_customers.sql` (line 17) | Day 0 | @dbt-labs/dx |
| Phase 2 | Update `customers.yml` line 13 — rename column doc from `customer_name` to `full_name` | Day 0 | @dbt-labs/dx |
| Phase 3 | Update `customers.yml` line 45 — rename MetricFlow semantic model dimension from `customer_name` to `full_name` | Day 0 | @dbt-labs/dx |
| Phase 4 | Run `dbt compile` to verify no SQL errors | Day 0 | @dbt-labs/dx |
| Phase 5 | Verify MetricFlow semantic model resolves `full_name` dimension correctly | Day 0 | @dbt-labs/dx |
| Phase 6 | Audit cross-repo consumers (BI dashboards, ML pipelines, external queries against `customers.customer_name`) | Day 0 | @dbt-labs/dx |

## Per-consumer migration steps

1. `models/staging/stg_customers.sql:17` — change `name as customer_name` to `name as full_name`
2. `models/marts/customers.yml:13` — change `- name: customer_name` (column doc) to `- name: full_name`; update description if it references the old name
3. `models/marts/customers.yml:45` — change `- name: customer_name` (MetricFlow dimension) to `- name: full_name`
4. `models/marts/customers.sql` — no change needed; uses `select *` so the renamed column propagates automatically

## Rollback triggers

- dbt compile failure after Phase 1
- MetricFlow dimension resolution failure after Phase 3
- Any BI dashboard or external query reporting missing `customer_name` column after deployment
- Any unexpected null count or data mismatch in `full_name` vs prior `customer_name` values

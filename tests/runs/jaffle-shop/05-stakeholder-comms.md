# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_name` → `full_name` in `stg_customers`.
>
> **Silent propagation warning:** `customers.sql` uses `SELECT *` and will automatically inherit the rename — no SQL error, but the `customers` mart output column changes name. Any BI dashboard or external query selecting `customers.customer_name` will break silently after deploy.
>
> In-repo impact:
> - `customers.sql` — output schema changes silently (SELECT * propagation, no dbt error)
> - `customers.yml` — MetricFlow semantic model dimension `customer_name` will fail at query time; column doc goes stale
>
> Coordinated single-PR update. @dbt-labs/dx owns both files (last edit: Benoit Perigaud).
>
> **Before merging:** audit any BI dashboard or ML pipeline reading from `customers.customer_name` — those are outside dbt compile-time checking. Reply if you know of any.

## PR description template

```
## Summary
Renames `customer_name` → `full_name` in `stg_customers`. All in-repo consumers updated in the same PR.

## Blast radius
- 1 dbt mart (`customers.sql`) — SILENT-PROPAGATION via SELECT *; output column renamed automatically, no dbt error
- 1 MetricFlow semantic model dimension (`customers.yml:45`) — WILL-BREAK at MetricFlow query time
- 1 column doc (`customers.yml:13`) — WILL-GO-STALE
- Cross-repo consumers (BI dashboards, ML pipelines) NOT verified — audit before merge

## Key risk
`customers.sql` produces NO dbt compile error. The failure surface is silent schema change in the mart
output. Any downstream consumer expecting `customer_name` from the `customers` table breaks post-deploy.

## Rollout
Coordinated single-PR. Verify MetricFlow resolves `full_name` dimension before merge.
Audit BI dashboards and external queries for `customers.customer_name` before deploy.

## References
- Migration plan: docs/data-changes/2026-05-15-rename-customer-name/04-migration-plan.md
- Risk assessment: docs/data-changes/2026-05-15-rename-customer-name/03-risk-assessment.md
```

## Changelog entry

```
### Changed
- `stg_customers.customer_name` renamed to `full_name`. The `customers` mart output column is
  renamed accordingly (propagated via SELECT *). MetricFlow semantic model dimension updated.
  All in-repo consumers updated in the same release. External consumers querying
  `customers.customer_name` must update column references before upgrading.
```

# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_name` → `full_name` in `stg_customers`.
>
> **Silent propagation warning:** `customers.sql` uses `SELECT *` and will silently pass the renamed column through to the `customers` mart — no SQL error, but the output column name changes. Any BI dashboard or external query selecting `customers.customer_name` will break silently after deploy.
>
> Affected in-repo:
> - `customers.sql` — SILENT-PROPAGATION via SELECT * (output column renamed automatically)
> - `customers.yml` — MetricFlow semantic model dimension `customer_name` will break at query time; column doc goes stale
>
> Coordinated update — single PR. MetricFlow owners: please verify the `customer_name` dimension still resolves after rename.
>
> Owner: @dbt-labs/dx. Cross-repo consumers (BI, ML) not verified — reply if you know of any.

## PR description template

```
## Summary
Renames `customer_name` → `full_name` in `stg_customers`. All in-repo consumers updated in same PR.

## Blast radius
- 1 dbt mart (`customers.sql`) — SILENT-PROPAGATION via SELECT *, output column name changes automatically
- 1 MetricFlow semantic model dimension (`customers.yml:45`) — WILL-BREAK at MetricFlow query time
- 1 column doc (`customers.yml:13`) — WILL-GO-STALE
- Cross-repo consumers (BI dashboards, ML feature pipelines) NOT verified — audit before merge

## Key risk
customers.sql produces NO compile error — the failure surfaces silently as a renamed output column.
Any consumer of the customers mart expecting `customer_name` by name will break without warning.

## Rollout
Coordinated single-PR update. Verify MetricFlow semantic model resolves before merge.
Audit BI dashboards and external SQL clients querying `customers.customer_name` before deploy.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-name/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-name/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_customers.customer_name` renamed to `full_name`. `customers` mart output column renamed accordingly.
  MetricFlow semantic model dimension updated. All in-repo consumers updated in same release.
  External consumers querying `customers.customer_name` must update their queries.
```

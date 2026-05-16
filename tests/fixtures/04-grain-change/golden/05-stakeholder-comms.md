# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — changing the grain of `dim_customers` from customer-level to household-level.
>
> **This is a semantic change, not a column rename.** No columns are added or removed. But every consumer that assumes one-row-per-customer will silently produce wrong results after this change.
>
> Affected: `fct_orders` (joins on customer_id — will produce incorrect aggregations).
>
> Rolling out as `dim_customers_v2` alongside the current model. 30-day migration window. Full plan in `docs/data-changes/<date>-grain-change-dim-customers/`.
>
> Owners unknown — if you maintain `fct_orders` or any model joining `dim_customers`, please reply or DM urgently.

## PR description template

```
## Summary
Changes `dim_customers` grain from customer-level to household-level via new `dim_customers_v2` model.

## Blast radius
- 1 downstream dbt model (`fct_orders`) with silent data correctness risk
- 1 schema doc requiring grain description update
- WARNING: semantic change — no compile errors, failure mode is silent data corruption

## Rollout
Versioned alias strategy. `dim_customers_v2` introduced at Day 0; `dim_customers` deprecated after 30-day migration window.

## References
- Migration plan: `docs/data-changes/<date>-grain-change-dim-customers/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-grain-change-dim-customers/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `dim_customers` grain changing from customer-level to household-level. New model: `dim_customers_v2`. Old model deprecated — removal in 30 days.
```

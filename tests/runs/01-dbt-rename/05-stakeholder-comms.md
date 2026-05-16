# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected dbt models: `dim_customers`, `fct_orders`. Schema docs also need updating.
>
> Rolling out with a 2-week deprecation window — both column names will be valid during that period. Full migration plan in `docs/data-changes/2026-05-15-rename-customer-age/`.
>
> No owners found for `dim_customers` or `fct_orders` — if you maintain either model, please reply or DM so we can coordinate.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 2 downstream dbt models affected: `dim_customers` (3 references), `fct_orders` (1 reference)
- 1 schema doc to update (`schema.yml`)
- No external (non-dbt) consumers detected in this repo

## Rollout
2-week deprecation window. Both column names valid during this period.
Old column removed on Day 14 after verification.

## References
- Migration plan: `docs/data-changes/2026-05-15-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/2026-05-15-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Deprecated
- `stg_customers.customer_age` — renamed to `customer_age_years`. Old name removed after 2-week deprecation window.
```

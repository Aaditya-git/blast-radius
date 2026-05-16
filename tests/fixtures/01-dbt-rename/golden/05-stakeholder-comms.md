# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected models: `dim_customers`, `fct_orders`.
>
> Rolling out with a 2-week deprecation window. Old column stays valid until then. Full migration plan in `docs/data-changes/<date>-rename-customer-age/`.
>
> Owners unknown for `dim_customers` and `fct_orders` — if you maintain either, please reply or DM.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 2 downstream dbt models affected (`dim_customers`, `fct_orders`)
- 1 schema doc to update
- No external (non-dbt) consumers detected

## Rollout
2-week deprecation window. Old column remains valid during this period.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Deprecated
- `stg_customers.customer_age` — renamed to `customer_age_years`. Old name removed on <date + 14 days>.
```

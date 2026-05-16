# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected: `dim_customers` (dbt model), `notebooks/eda.ipynb` (4 references across SQL string and DataFrame access).
>
> Coordinated update — single PR. Notebook owner: please verify the updated notebook runs correctly in staging before merge.
>
> No owner on record for `eda.ipynb` — if you maintain this notebook, please reply or DM.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 1 downstream dbt model (`dim_customers`) — DIRECT, will-break at compile time
- 1 EDA notebook (`notebooks/eda.ipynb`) — TRANSITIVE depth 2, 4 references across SQL + DataFrame, will-break at runtime

## Rollout
Coordinated update — single PR. Execute notebook in staging to verify before merge.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_customers.customer_age` renamed to `customer_age_years`. All consumers updated in same release.
```

# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected: `dim_customers` (dbt model), `notebooks/eda.ipynb` (SQL string referencing the column 4 times).
>
> Coordinated update — single PR. Notebook owner: please review and verify the updated notebook runs correctly.
>
> If you maintain `eda.ipynb`, please reply or DM — we have no owner on record.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 1 downstream dbt model (`dim_customers`)
- 1 EDA notebook (`notebooks/eda.ipynb`) with 4 SQL/DataFrame references

## Rollout
Coordinated update — single PR, run notebook in staging before merge.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_customers.customer_age` renamed to `customer_age_years`. All consumers updated in same release.
```

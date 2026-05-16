# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected: `dim_customers` (dbt), `extract_age_features.py` (Spark), `customer_features_dag.yml` (Airflow).
>
> Coordinated update — all changes go in one PR. Staging validation required before merge.
>
> Owners unknown for all affected files — if you maintain any of these, please reply or DM.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 1 downstream dbt model (`dim_customers`)
- 1 Python Spark pipeline (`extract_age_features.py`)
- 1 Airflow DAG config (`customer_features_dag.yml`)

## Rollout
Coordinated update — single PR, staging validation before merge.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_customers.customer_age` renamed to `customer_age_years`. All consumers updated in same release.
```

# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected across 3 stacks: `dim_customers` (dbt), `extract_age_features.py` (Spark), `customer_features_dag.yml` (Airflow).
>
> Coordinated update — all changes go in one PR. Staging Spark run required before merge.
>
> No owners on record for any affected files — if you maintain any of these, please reply or DM before this merges.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 1 downstream dbt model (`dim_customers`) — DIRECT, will-break at compile time
- 1 Python Spark pipeline (`extract_age_features.py`) — TRANSITIVE depth 2, will-break at runtime
- 1 Airflow DAG config (`customer_features_dag.yml`) — TRANSITIVE depth 2, config goes stale

## Rollout
Coordinated update — single PR. Staging Spark validation required before merge.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_customers.customer_age` renamed to `customer_age_years`. All consumers (dbt, Spark, Airflow) updated in same release.
```

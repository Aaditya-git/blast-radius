# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> FYI — renaming internal CTE `base` → `customers_base` in `dim_customers.sql`.
>
> **No external impact.** Output columns are unchanged. Zero consumer coordination required.
>
> Deploying directly.

## PR description template

```
## Summary
Internal refactor: rename CTE `base` → `customers_base` in `dim_customers.sql`.

## Blast radius
- 0 external consumers affected
- Change is internal to `dim_customers.sql` — output columns unchanged

## Rollout
Hard cut. No deprecation window needed.

## References
- Risk assessment: `docs/data-changes/<date>-rename-cte-base/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- Internal refactor of `dim_customers.sql` CTE naming. No external impact.
```

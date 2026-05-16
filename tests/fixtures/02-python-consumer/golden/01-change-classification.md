# Stage 1 — Change Classification

## Change summary
Rename column `customer_age` to `customer_age_years` in `stg_customers`.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Breaking |
| Surface | Column |

## Reasoning

- **Structural** — the change affects the physical schema (column name), not business semantics
- **Breaking** — the old column will not exist; any consumer referencing `customer_age` will fail to compile or return an error at query time
- **Surface: Column** — the change is scoped to a single column on a single model

# Stage 1 — Change Classification

## Change summary
Rename column `customer_name` to `full_name` in `stg_customers`. Currently defined on line 17 of `models/staging/stg_customers.sql` as `name as customer_name`. After this change, the column will be exposed as `full_name`. The old column name will not exist — no backward compatibility shim is provided.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Breaking |
| Surface | Column |

## Reasoning

- **Structural** — the change affects the physical schema: a column is being renamed (`customer_name` → `full_name`), not the logic or location of the data
- **Breaking** — the old column name `customer_name` will cease to exist; any consumer referencing it by name will fail at compile or runtime; consumers using `SELECT *` will silently change their output schema
- **Surface: Column** — the change is scoped to a single column on a single model (`stg_customers`)

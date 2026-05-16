# Stage 1 — Change Classification

**Repo:** github.com/dbt-labs/jaffle-shop (commit: shallow clone, May 2026)

## Change summary
Rename column `customer_name` to `full_name` in `stg_customers`. The old column will not exist after this change — no backward compatibility shim is provided.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Breaking |
| Surface | Column |

## Reasoning

- **Structural** — the change affects the physical schema: a column is being renamed, not the logic or location of the data
- **Breaking** — the old column name `customer_name` will cease to exist; any consumer referencing it by name will fail at compile or runtime
- **Surface: Column** — the change is scoped to a single column on a single model (`stg_customers`)

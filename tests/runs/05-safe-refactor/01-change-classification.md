# Stage 1 — Change Classification

## Change summary
Rename the CTE `base` to `customers_base` inside `dim_customers.sql`. The CTE is internal to this file and not referenced externally. Output columns are unchanged.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Safe |
| Surface | Model (internal) |

## Reasoning

- **Structural** — a named object (the CTE `base`) is being renamed
- **Safe** — CTEs are scoped to the SQL statement they appear in; external consumers reference the model's output columns, not internal CTE names. No externally visible output changes.
- **Surface: Model (internal)** — the change is entirely within one model's SQL body and has no external surface area

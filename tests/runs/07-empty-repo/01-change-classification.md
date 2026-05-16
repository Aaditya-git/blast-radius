# Stage 1 — Change Classification

## Change summary
Rename column `event_type` to `event_category` in `stg_events`.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Breaking |
| Surface | Column |

## Reasoning

- **Structural** — the change affects the physical schema (column name)
- **Breaking** — the old column will not exist; any consumer referencing `event_type` will fail
- **Surface: Column** — scoped to a single column on a single model

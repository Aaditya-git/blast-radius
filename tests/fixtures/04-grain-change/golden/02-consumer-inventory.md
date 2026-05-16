# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/04-grain-change`
- Patterns searched: `dim_customers` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 2 SQL files, 1 YAML file

## Consumers found

### fct_orders.sql (dbt model)
- **Path:** `models/marts/fct_orders.sql:7`
- **Stack:** dbt
- **Usage:** JOIN (joins dim_customers on customer_id — assumes one row per customer_id)
- **Snippet:** `join {{ ref('dim_customers') }} c using (customer_id)`

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:3`
- **Stack:** dbt
- **Usage:** DOCUMENTATION (grain documented as customer-level)
- **Snippet:** `description: "One row per customer. Grain: customer_id."`

## Summary
- Total consumers: 2 files, 2 references
- Stacks affected: dbt only
- Note: Semantic grain changes are particularly dangerous — JOIN consumers will not fail at compile time but will silently produce incorrect aggregations

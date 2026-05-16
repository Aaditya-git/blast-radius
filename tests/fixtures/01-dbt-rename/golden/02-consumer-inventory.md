# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/01-dbt-rename`
- Patterns searched: `customer_age` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 4 SQL files, 1 YAML file

## Consumers found

### dim_customers.sql (dbt model)
- **Path:** `models/marts/dim_customers.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (direct reference)
- **Snippet:** `customer_age,`
- **Also:** `models/marts/dim_customers.sql:6-8` references `customer_age` in CASE expression for `age_bucket`

### fct_orders.sql (dbt model)
- **Path:** `models/marts/fct_orders.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (via join)
- **Snippet:** `c.customer_age,`

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:7, 14`
- **Stack:** dbt
- **Usage:** column documentation
- **Snippet:** `- name: customer_age` (appears twice — under dim_customers and fct_orders)

## Summary
- Total consumers: 3 files, 5 references
- Stacks affected: dbt only
- No cross-repo dependencies detected (single-repo search)

# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/03-notebook-consumer`
- Patterns searched: `customer_age` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 2 SQL files, 1 notebook

## Consumers found

### dim_customers.sql (dbt model)
- **Path:** `models/marts/dim_customers.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (direct reference)
- **Snippet:** `customer_age,`

### eda.ipynb (notebook)
- **Path:** `notebooks/eda.ipynb` (SQL cell, lines 6-8)
- **Stack:** notebook
- **Usage:** SELECT (SQL string in pd.read_sql)
- **Snippet:** `customer_age,`
- **Also:** `customer_age` referenced in CASE expression (lines 9-13) and WHERE clause (line 15), and in histogram cell via `df['customer_age']`

## Summary
- Total consumers: 2 files, 5 references
- Stacks affected: dbt, notebook
- No cross-repo dependencies detected (single-repo search)

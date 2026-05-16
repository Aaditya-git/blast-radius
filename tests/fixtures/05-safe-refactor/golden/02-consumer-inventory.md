# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/05-safe-refactor`
- Patterns searched: `base` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 2 SQL files

## Consumers found

### dim_customers.sql (internal CTE definition only)
- **Path:** `models/marts/dim_customers.sql:1,8`
- **Stack:** dbt
- **Usage:** ASSIGNMENT (CTE definition) + internal SELECT
- **Snippet:** `with base as (` and `select * from base`
- **Note:** Both references are inside `dim_customers.sql` itself. No external consumer references the CTE name `base`.

## Summary
- Total consumers: 1 file, 2 references (both internal)
- External consumers: 0
- Stacks affected: none externally
- This change is safe — no external consumers will be affected

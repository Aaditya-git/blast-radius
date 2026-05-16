# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/04-grain-change`. Extracted inputs/outputs per file:
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `models/marts/fct_orders.sql` → produces: `fct_orders`; reads: `source('raw', 'orders')`, `ref('dim_customers')`
- `models/marts/schema.yml` → documents: `dim_customers` (grain description, column descriptions)

Seed: `dim_customers` (the model whose grain is changing)

BFS traversal:
- Depth 1: `fct_orders.sql` reads `dim_customers` via JOIN → added; queue `fct_orders`
- Depth 1: `schema.yml` documents `dim_customers` → added
- No further consumers found → queue empty

## Impact tree

```
dim_customers (CHANGED — grain: customer → household)
├── fct_orders.sql [dbt] — DIRECT — WILL-BREAK (silent data corruption)
└── schema.yml [dbt doc] — DIRECT — WILL-GO-STALE
```

## Consumer details

### fct_orders.sql (dbt)
- **Path:** `models/marts/fct_orders.sql:7`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('dim_customers')`)
- **Break classification:** WILL-BREAK (silent data corruption — no compile error)
- **Usage:** JOIN (joins dim_customers on customer_id; assumes one row per customer_id)
- **Snippet:** `join {{ ref('dim_customers') }} c using (customer_id)`
- **Column explicitly referenced:** N/A (grain change — join semantics affected across all columns)
- **Note:** After the grain change, this join will fan out — one order row will match multiple household members, silently multiplying aggregations.

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:3`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1)
- **Break classification:** WILL-GO-STALE
- **Usage:** DOCUMENTATION (grain description, customer_id described as primary key)
- **Snippet:** `description: "One row per customer. Grain: customer_id."` and `description: "Primary key — unique per customer"`
- **Column explicitly referenced:** N/A

## Summary
- Total impacted: 2 files across 1 stack
- Direct consumers: 2
- Transitive consumers: 0
- Silent propagation (SELECT *): 0
- Stacks affected: dbt
- Max impact tree depth: 1
- Semantic change warning: no compile errors will surface — failure mode is silent data corruption in any downstream aggregation or JOIN that assumed customer_id uniqueness
- Cross-repo consumers: not visible in this search — verify separately

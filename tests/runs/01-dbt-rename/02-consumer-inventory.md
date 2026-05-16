# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/01-dbt-rename`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `models/marts/fct_orders.sql` → produces: `fct_orders`; reads: `source('raw', 'orders')`, `ref('stg_customers')`
- `models/marts/schema.yml` → documents: `dim_customers`, `fct_orders` columns

Seed: `stg_customers` (contains changed column `customer_age`)

BFS traversal: depth 1 → dim_customers, fct_orders, schema.yml. Depth 2: no further consumers of dim_customers or fct_orders in this repo.

## Impact tree

```
stg_customers.customer_age (CHANGED)
├── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
├── fct_orders.sql [dbt] — DIRECT — WILL-BREAK
└── schema.yml [dbt doc] — DIRECT — WILL-GO-STALE
```

## Consumer details

### dim_customers.sql (dbt)
- **Path:** `models/marts/dim_customers.sql:4,6,7`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (line 4: direct column reference; lines 6-7: CASE expression using `customer_age`)
- **Snippet:** `customer_age,` and `when customer_age < 25 then 'young'`
- **Column explicitly referenced:** Yes (3 references)

### fct_orders.sql (dbt)
- **Path:** `models/marts/fct_orders.sql:4`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')` via JOIN)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (via join alias `c`)
- **Snippet:** `c.customer_age,`
- **Column explicitly referenced:** Yes

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:7,14`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1)
- **Break classification:** WILL-GO-STALE
- **Usage:** DOCUMENTATION (column name listed under dim_customers and fct_orders)
- **Snippet:** `- name: customer_age` (appears twice)
- **Column explicitly referenced:** Yes

## Summary
- Total impacted: 3 files across 1 stack
- Direct consumers: 3
- Transitive consumers: 0
- Silent propagation (SELECT *): 0
- Stacks affected: dbt
- Max impact tree depth: 1
- Cross-repo consumers: not visible in this search — verify separately

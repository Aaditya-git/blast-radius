# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/01-dbt-rename`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `models/marts/fct_orders.sql` → produces: `fct_orders`; reads: `source('raw', 'orders')`, `ref('stg_customers')`
- `models/marts/schema.yml` → documents: `dim_customers`, `fct_orders` columns

Seed: `stg_customers` (contains changed column `customer_age`)

## Impact tree

```
stg_customers.customer_age (CHANGED)
├── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
├── fct_orders.sql [dbt] — DIRECT — WILL-BREAK
└── schema.yml [dbt doc] — DIRECT — WILL-GO-STALE
```

## Consumer details

### dim_customers.sql (dbt)
- **Path:** `models/marts/dim_customers.sql:4,6-8`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (explicit reference on line 4; also in CASE expression lines 6-8)
- **Snippet:** `customer_age,`
- **Column explicitly referenced:** Yes

### fct_orders.sql (dbt)
- **Path:** `models/marts/fct_orders.sql:4`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')` via join)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (via join alias)
- **Snippet:** `c.customer_age,`
- **Column explicitly referenced:** Yes

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:7,14`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1)
- **Break classification:** WILL-GO-STALE
- **Usage:** DOCUMENTATION
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

# Stage 2 — Consumer Inventory

**Repo:** github.com/dbt-labs/jaffle-shop

## Dependency graph construction

Scanned all files in the repo. Extracted inputs/outputs per file:

**Staging (producers):**
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('ecom', 'raw_customers')`
- `models/staging/stg_locations.sql` → produces: `stg_locations`; reads: `source('ecom', 'raw_stores')`
- `models/staging/stg_order_items.sql` → produces: `stg_order_items`; reads: `source('ecom', 'raw_items')`
- `models/staging/stg_orders.sql` → produces: `stg_orders`; reads: `source('ecom', 'raw_orders')`
- `models/staging/stg_products.sql` → produces: `stg_products`; reads: `source('ecom', 'raw_products')`
- `models/staging/stg_supplies.sql` → produces: `stg_supplies`; reads: `source('ecom', 'raw_supplies')`

**Marts (consumers):**
- `models/marts/customers.sql` → produces: `customers`; reads: `ref('stg_customers')` (SELECT *), `ref('orders')`
- `models/marts/locations.sql` → produces: `locations`; reads: `ref('stg_locations')` (SELECT *)
- `models/marts/orders.sql` → produces: `orders`; reads: `ref('stg_orders')` (SELECT *), `ref('order_items')`
- `models/marts/order_items.sql` → produces: `order_items`; reads: `ref('stg_order_items')`, `ref('stg_orders')`, `ref('stg_products')`, `ref('stg_supplies')`
- `models/marts/products.sql` → produces: `products`; reads: `ref('stg_products')` (SELECT *)
- `models/marts/supplies.sql` → produces: `supplies`; reads: `ref('stg_supplies')` (SELECT *)
- `models/marts/metricflow_time_spine.sql` → produces: `metricflow_time_spine`; reads: dbt_date macro (no model refs)

**Schema docs:**
- `models/staging/stg_customers.yml` → documents: `stg_customers` (columns: `customer_id` only — `customer_name` not documented here)
- `models/marts/customers.yml` → documents: `customers` + MetricFlow semantic model; explicitly references `customer_name` at line 13 (column doc) and line 45 (semantic model dimension)

Seed: `stg_customers` (contains changed column `customer_name`)

BFS traversal:
- Depth 1: `customers.sql` reads `ref('stg_customers')` with `select *` → SILENT-PROPAGATION added; queue `customers`
- Depth 1: `stg_customers.yml` documents `stg_customers` — no `customer_name` column documented → no impact
- Depth 2: `customers.yml` documents `customers` model with explicit `customer_name` references — WILL-BREAK (MetricFlow dimension) and WILL-GO-STALE (column doc) → added
- Depth 2: No other files read `ref('customers')` → queue empty

## Impact tree

```
stg_customers.customer_name (CHANGED → full_name)
└── customers.sql [dbt] — DIRECT — SILENT-PROPAGATION (SELECT *)
    └── customers.yml [dbt doc + MetricFlow] — TRANSITIVE depth 2 — WILL-BREAK (semantic model) + WILL-GO-STALE (column doc)
```

## Consumer details

### customers.sql (dbt)
- **Path:** `models/marts/customers.sql:5`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')`)
- **Break classification:** SILENT-PROPAGATION
- **Usage:** `select * from {{ ref('stg_customers') }}` — inherits all columns including `customer_name` without naming it
- **Snippet:** `select * from {{ ref('stg_customers') }}`
- **Column explicitly referenced:** No (SELECT * — column flows through without being named)
- **Note:** No compile error. The output of `customers` will silently change from `customer_name` to `full_name`. Any downstream system expecting `customer_name` from the `customers` table will break. **This consumer is invisible to a simple grep for `customer_name`.**

### customers.yml (dbt schema doc + MetricFlow semantic model)
- **Path:** `models/marts/customers.yml:13` (column doc), `models/marts/customers.yml:45` (MetricFlow dimension)
- **Stack:** dbt / MetricFlow
- **Impact:** TRANSITIVE (depth 2, via `customers.sql` SELECT * propagation)
- **Break classification:** WILL-BREAK (MetricFlow semantic model dimension) + WILL-GO-STALE (column documentation)
- **Usage:**
  - Line 13: `- name: customer_name` — dbt column description (will be factually wrong)
  - Line 45: `- name: customer_name` inside `dimensions:` of the MetricFlow semantic model — **will fail at MetricFlow query time when resolving the dimension**
- **Snippet:** `- name: customer_name` (×2)
- **Column explicitly referenced:** Yes (×2)
- **Note:** The MetricFlow semantic model dimension reference is a hard failure — MetricFlow will not be able to resolve the `customer_name` dimension after the rename. The column doc on line 13 will silently become stale.

## Summary
- Total impacted: 2 files across 1 stack (dbt / MetricFlow)
- Direct consumers: 1 (`customers.sql`)
- Transitive consumers: 1 (`customers.yml`)
- **Silent propagation (SELECT *): 1** — `customers.sql` is completely invisible to grep; only graph traversal finds it
- Stacks affected: dbt, MetricFlow
- Max impact tree depth: 2
- Owner: `@dbt-labs/dx` (per `.github/CODEOWNERS`)
- Cross-repo consumers: not visible in this search — verify BI tools, ML platforms, or external queries against the `customers` table

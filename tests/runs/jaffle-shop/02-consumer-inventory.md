# Stage 2 — Consumer Inventory

## Dependency graph construction

Building dependency graph across all file types in `/tmp/jaffle-shop`...

Scanned 37 files (14 dbt models, 10 schema YAMLs, 3 CI workflow YAMLs, 1 Python script, macros, config). Extracted inputs/outputs per file:

**Staging models (producers):**
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('ecom', 'raw_customers')`; SELECT * internally (CTE-local only)
- `models/staging/stg_locations.sql` → produces: `stg_locations`; reads: `source('ecom', 'raw_stores')`
- `models/staging/stg_order_items.sql` → produces: `stg_order_items`; reads: `source('ecom', 'raw_items')`
- `models/staging/stg_orders.sql` → produces: `stg_orders`; reads: `source('ecom', 'raw_orders')`
- `models/staging/stg_products.sql` → produces: `stg_products`; reads: `source('ecom', 'raw_products')`
- `models/staging/stg_supplies.sql` → produces: `stg_supplies`; reads: `source('ecom', 'raw_supplies')`

**Mart models (consumers):**
- `models/marts/customers.sql` → produces: `customers`; reads: `ref('stg_customers')` (**SELECT \***), `ref('orders')`
- `models/marts/locations.sql` → produces: `locations`; reads: `ref('stg_locations')` (SELECT *)
- `models/marts/orders.sql` → produces: `orders`; reads: `ref('stg_orders')` (SELECT *), `ref('order_items')`
- `models/marts/order_items.sql` → produces: `order_items`; reads: `ref('stg_order_items')`, `ref('stg_orders')`, `ref('stg_products')`, `ref('stg_supplies')`
- `models/marts/products.sql` → produces: `products`; reads: `ref('stg_products')` (SELECT *)
- `models/marts/supplies.sql` → produces: `supplies`; reads: `ref('stg_supplies')` (SELECT *)
- `models/marts/metricflow_time_spine.sql` → produces: `metricflow_time_spine`; reads: dbt_date macro only

**Schema docs / semantic models:**
- `models/staging/stg_customers.yml` → documents: `stg_customers`; columns documented: `customer_id` only — `customer_name` not documented here
- `models/marts/customers.yml` → documents: `customers` mart + MetricFlow semantic model (`model: ref('customers')`); explicitly references `customer_name` at line 13 (column doc) and line 45 (MetricFlow dimension)

**CI / scripts:**
- `.github/workflows/cd_prod.yml`, `cd_staging.yml`, `ci.yml` — invoke dbt Cloud jobs; no direct table references
- `.github/workflows/scripts/dbt_cloud_run_job.py` — API client for dbt Cloud; no table references

Graph: **14 objects mapped, 8 consumer edges found**

Seed: `stg_customers` (contains changed column `customer_name`)

BFS traversal:
- Depth 1: `customers.sql` reads `ref('stg_customers')` with `select *` → SILENT-PROPAGATION added; queue `customers`
- Depth 1: `stg_customers.yml` documents `stg_customers` — no `customer_name` column documented → no impact
- Depth 2: `customers.yml` documents `customers` with explicit `customer_name` at line 13 (column doc → WILL-GO-STALE) and line 45 (MetricFlow dimension → WILL-BREAK) → added
- Depth 2: No other file reads `ref('customers')` as a data consumer → queue empty

## Impact tree

```
stg_customers.customer_name (CHANGED → full_name)
└── customers.sql [dbt] — DIRECT — SILENT-PROPAGATION (SELECT *)
    └── customers.yml [dbt doc + MetricFlow] — TRANSITIVE depth 2 — WILL-BREAK (MetricFlow dimension) + WILL-GO-STALE (column doc)
```

## Consumer details

### customers.sql (dbt)
- **Path:** `models/marts/customers.sql:5`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')`)
- **Break classification:** SILENT-PROPAGATION
- **Usage:** `select * from {{ ref('stg_customers') }}` — inherits all columns including `customer_name` without naming it explicitly; the renamed column propagates silently to the `customers` mart output
- **Snippet:** `select * from {{ ref('stg_customers') }}`
- **Column explicitly referenced:** No (SELECT * — column flows through without being named)
- **Note:** No compile error will fire. The output schema of the `customers` mart changes silently — `customer_name` becomes `full_name`. Any downstream system (BI tool, ML pipeline, external query) selecting `customers.customer_name` will break without warning. **This consumer is completely invisible to `grep -r customer_name`.**

### customers.yml (dbt schema doc + MetricFlow semantic model)
- **Path:** `models/marts/customers.yml:13` (column doc), `models/marts/customers.yml:45` (MetricFlow dimension)
- **Stack:** dbt / MetricFlow
- **Impact:** TRANSITIVE (depth 2, via `customers.sql` SELECT * propagation)
- **Break classification:** WILL-BREAK (MetricFlow dimension) + WILL-GO-STALE (column doc)
- **Usage:**
  - Line 13: `- name: customer_name` — dbt column description (will be factually wrong after rename, no runtime failure)
  - Line 45: `- name: customer_name` inside `dimensions:` of the MetricFlow semantic model — MetricFlow will fail to resolve this dimension after rename
- **Snippet:** `- name: customer_name` (×2 — line 13 and line 45)
- **Column explicitly referenced:** Yes (×2)

## Summary
- Total impacted: 2 files across 2 stacks (dbt, MetricFlow)
- Direct consumers: 1 (`customers.sql`)
- Transitive consumers: 1 (`customers.yml`)
- **Silent propagation (SELECT \*): 1** — `customers.sql` invisible to grep; only graph traversal finds it
- Stacks affected: dbt, MetricFlow
- Max impact tree depth: 2
- Owner: `@dbt-labs/dx` (per `.github/CODEOWNERS`)
- Cross-repo consumers: not visible in this search — verify BI tools (Tableau, Looker, Metabase), ML feature pipelines, and any external SQL client querying the `customers` table

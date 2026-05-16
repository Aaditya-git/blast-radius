# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/03-notebook-consumer`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `notebooks/eda.ipynb` → reads: `dim_customers` (SQL string in pd.read_sql); no write output

Seed: `stg_customers` (contains changed column `customer_age`)

## Impact tree

```
stg_customers.customer_age (CHANGED)
└── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
    └── eda.ipynb [notebook] — TRANSITIVE depth 2 — WILL-BREAK
```

## Consumer details

### dim_customers.sql (dbt)
- **Path:** `models/marts/dim_customers.sql:4`
- **Stack:** dbt
- **Impact:** DIRECT (depth 1, reads `ref('stg_customers')`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (explicit reference)
- **Snippet:** `customer_age,`
- **Column explicitly referenced:** Yes

### eda.ipynb (notebook)
- **Path:** `notebooks/eda.ipynb` (code cell, SQL string lines 6-8, DataFrame access line 18)
- **Stack:** notebook
- **Impact:** TRANSITIVE (depth 2, via `dim_customers`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT + WHERE + DataFrame column access (4 references in SQL string and Python)
- **Snippet:** `customer_age,` in SELECT; `customer_age` in CASE and WHERE; `df['customer_age']` in plot cell
- **Column explicitly referenced:** Yes

## Summary
- Total impacted: 2 files across 2 stacks
- Direct consumers: 1
- Transitive consumers: 1 (would be missed by simple grep on stg_customers)
- Silent propagation (SELECT *): 0
- Stacks affected: dbt, notebook
- Max impact tree depth: 2
- Cross-repo consumers: not visible in this search — verify separately

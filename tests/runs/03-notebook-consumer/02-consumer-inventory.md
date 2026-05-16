# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/03-notebook-consumer`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `notebooks/eda.ipynb` → reads: `dim_customers` (FROM clause in pd.read_sql SQL string, sql-query cell); no write output

Seed: `stg_customers` (contains changed column `customer_age`)

BFS traversal:
- Depth 1: `dim_customers.sql` reads `stg_customers` → added; queue `dim_customers`
- Depth 2: `eda.ipynb` reads `dim_customers` (pd.read_sql FROM clause) → added
- No further consumers of `dim_customers` → queue empty

## Impact tree

```
stg_customers.customer_age (CHANGED)
└── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
    └── eda.ipynb [notebook] — TRANSITIVE depth 2 — WILL-BREAK (runtime)
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
- **Path:** `notebooks/eda.ipynb` (sql-query cell: SELECT line 9, CASE lines 11-13, WHERE line 15; plot cell: DataFrame access)
- **Stack:** notebook
- **Impact:** TRANSITIVE (depth 2, via `dim_customers`)
- **Break classification:** WILL-BREAK (runtime)
- **Usage:** SELECT + WHERE + CASE + DataFrame column access (4 references total)
- **Snippet:** `customer_age,` in SELECT; `customer_age < 25` in CASE; `WHERE customer_age IS NOT NULL`; `df['customer_age'].hist(bins=20)`
- **Column explicitly referenced:** Yes (4 references across 2 cells)
- **Note:** No compile-time error — failure surfaces only when the notebook SQL cell is executed

## Summary
- Total impacted: 2 files across 2 stacks
- Direct consumers: 1
- Transitive consumers: 1 (would be missed by simple grep on `stg_customers`)
- Silent propagation (SELECT *): 0
- Stacks affected: dbt, notebook
- Max impact tree depth: 2
- Cross-repo consumers: not visible in this search — verify separately

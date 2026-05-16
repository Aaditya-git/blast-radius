# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/02-python-consumer`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `pipelines/extract_age_features.py` → reads: `analytics.dim_customers` (spark.read.table line 5); produces: `analytics.customer_age_features` (saveAsTable line 14)
- `dags/customer_features_dag.yml` → reads: `analytics.dim_customers` (source_table line 13); triggers: `extract_age_features` pipeline

Seed: `stg_customers` (contains changed column `customer_age`)

BFS traversal:
- Depth 1: `dim_customers.sql` reads `stg_customers` → added
- Depth 2: `extract_age_features.py` reads `analytics.dim_customers` → added; `customer_features_dag.yml` reads `analytics.dim_customers` → added
- Depth 3: no consumers of `analytics.customer_age_features` in this repo → queue empty

## Impact tree

```
stg_customers.customer_age (CHANGED)
└── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
    ├── extract_age_features.py [Python] — TRANSITIVE depth 2 — WILL-BREAK
    └── customer_features_dag.yml [orchestration] — TRANSITIVE depth 2 — TRANSITIVE-RISK
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

### extract_age_features.py (Python)
- **Path:** `pipelines/extract_age_features.py:10,11`
- **Stack:** Python
- **Impact:** TRANSITIVE (depth 2, via `dim_customers`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (Spark df.select string literal line 10) + arithmetic expression (df.customer_age line 11)
- **Snippet:** `"customer_age",` and `(df.customer_age / 10).cast("int").alias("age_decade")`
- **Column explicitly referenced:** Yes (2 references)

### customer_features_dag.yml (orchestration)
- **Path:** `dags/customer_features_dag.yml:11,13`
- **Stack:** orchestration
- **Impact:** TRANSITIVE (depth 2, via `dim_customers`)
- **Break classification:** TRANSITIVE-RISK
- **Usage:** CONFIG — `customer_age` listed in `feature_columns` (line 11); `source_table: analytics.dim_customers` (line 13)
- **Snippet:** `- customer_age` and `source_table: analytics.dim_customers`
- **Column explicitly referenced:** Yes (in config)

## Summary
- Total impacted: 3 files across 3 stacks
- Direct consumers: 1
- Transitive consumers: 2 (would be missed by simple grep on `stg_customers`)
- Silent propagation (SELECT *): 0
- Stacks affected: dbt, Python, orchestration
- Max impact tree depth: 2
- Cross-repo consumers: not visible in this search — verify separately

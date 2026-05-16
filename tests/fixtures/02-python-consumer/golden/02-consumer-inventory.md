# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/02-python-consumer`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`
- `pipelines/extract_age_features.py` → reads: `analytics.dim_customers`; produces: `analytics.customer_age_features`
- `dags/customer_features_dag.yml` → triggers: `extract_age_features` pipeline reading `analytics.dim_customers`

Seed: `stg_customers` (contains changed column `customer_age`)

## Impact tree

```
stg_customers.customer_age (CHANGED)
└── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
    └── extract_age_features.py [Python] — TRANSITIVE depth 2 — WILL-BREAK
        └── customer_features_dag.yml [orchestration] — TRANSITIVE depth 3 — TRANSITIVE-RISK
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
- **Path:** `pipelines/extract_age_features.py:9,10`
- **Stack:** Python
- **Impact:** TRANSITIVE (depth 2, via `dim_customers`)
- **Break classification:** WILL-BREAK
- **Usage:** SELECT (Spark column reference) + arithmetic expression
- **Snippet:** `"customer_age",` and `df.customer_age`
- **Column explicitly referenced:** Yes

### customer_features_dag.yml (orchestration)
- **Path:** `dags/customer_features_dag.yml:11`
- **Stack:** orchestration
- **Impact:** TRANSITIVE (depth 3, via `dim_customers` → `extract_age_features.py`)
- **Break classification:** TRANSITIVE-RISK
- **Usage:** CONFIG (feature_columns list)
- **Snippet:** `- customer_age`
- **Column explicitly referenced:** Yes (in config)

## Summary
- Total impacted: 3 files across 3 stacks
- Direct consumers: 1
- Transitive consumers: 2 (would be missed by simple grep on stg_customers)
- Silent propagation (SELECT *): 0
- Stacks affected: dbt, Python, orchestration
- Max impact tree depth: 3
- Cross-repo consumers: not visible in this search — verify separately

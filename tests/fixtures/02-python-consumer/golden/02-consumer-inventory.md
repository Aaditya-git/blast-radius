# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/02-python-consumer`
- Patterns searched: `customer_age` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 2 SQL files, 1 Python file, 1 YAML file

## Consumers found

### dim_customers.sql (dbt model)
- **Path:** `models/marts/dim_customers.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (direct reference)
- **Snippet:** `customer_age,`

### extract_age_features.py (Python pipeline)
- **Path:** `pipelines/extract_age_features.py:9`
- **Stack:** Python
- **Usage:** SELECT (Spark column reference)
- **Snippet:** `"customer_age",`
- **Also:** `pipelines/extract_age_features.py:10` — `df.customer_age` used in arithmetic expression for `age_decade`

### customer_features_dag.yml (Airflow DAG)
- **Path:** `dags/customer_features_dag.yml:11`
- **Stack:** orchestration
- **Usage:** configuration reference (feature_columns list)
- **Snippet:** `- customer_age`

## Summary
- Total consumers: 3 files, 4 references
- Stacks affected: dbt, Python, orchestration (Airflow YAML)
- No cross-repo dependencies detected (single-repo search)

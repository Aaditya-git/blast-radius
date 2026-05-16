# Stage 2 — Trace consumers

## Input
- The changed object (table or column name) from Stage 1
- The repo root (default: cwd)

## What to do

### Phase A — Fast grep

Run grep for the literal name across these globs:
- `*.sql`
- `*.py`
- `*.yml`, `*.yaml`
- `*.ipynb`

Excludes: `.git`, `node_modules`, `.venv`, `dist`, `build`, `__pycache__`.

Announce the search before running:
> Searching for 'customer_age' in *.sql, *.py, *.yml, *.ipynb across repo root...

### Phase B — Classify each hit

For each file with a hit, read the file and identify the stack:

| File pattern | Stack |
|---|---|
| `*.sql` with `{{ ref(...) }}` or `{{ source(...) }}` | dbt model |
| `*.sql` without dbt jinja | raw SQL |
| `*.py` with `pd.read_sql`, `spark.read.table`, or SQL strings | Python |
| `schema.yml`, `*.yml` with `version: 2` | dbt schema doc |
| `*.ipynb` | notebook |
| Airflow DAG file (has `from airflow`) | orchestration |

### Phase C — Extract usage context

For each hit, classify how the column/table is used:
- **SELECT** — listed in a select clause (will-break on rename)
- **WHERE / FILTER** — used in predicate (will-break)
- **JOIN** — used in join condition (will-break)
- **ASSIGNMENT** — defining the column (this IS the source)
- **DOCUMENTATION** — schema.yml entry (will go stale)
- **COMMENT ONLY** — just in a code comment (safe)

## Output

Write artifact to `docs/data-changes/<slug>/02-consumer-inventory.md`. Stream entries as you find them — do not buffer.

Structure:

```markdown
# Stage 2 — Consumer Inventory

## Search scope
- Repo root: <path>
- Patterns searched: <name> in <globs>
- Files scanned: <count> by file type

## Consumers found

### <filename> (<stack>)
- **Path:** <path>:<line>
- **Stack:** <stack>
- **Usage:** <SELECT|WHERE|JOIN|ASSIGNMENT|DOCUMENTATION>
- **Snippet:** `<one-line snippet>`

(... repeat for each consumer)

## Summary
- Total consumers: <count> files, <count> references
- Stacks affected: <list>
- Notes: <any caveats — parse failures, cross-repo flags>
```

## Failure modes

- Zero consumers found → state explicitly at the top of the inventory: "No consumers found in scope. This does NOT imply safety — verify scope is correct and consider broadening search."
- Parse failure on a file → list it under "Parse failures — manual review required" rather than silently skipping.

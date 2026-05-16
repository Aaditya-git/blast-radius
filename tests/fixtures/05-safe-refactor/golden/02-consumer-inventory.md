# Stage 2 — Consumer Inventory

## Dependency graph construction
Scanned all files in `tests/fixtures/05-safe-refactor`. Extracted inputs/outputs per file:
- `models/staging/stg_customers.sql` → produces: `stg_customers`; reads: `source('raw', 'customers')`
- `models/marts/dim_customers.sql` → produces: `dim_customers`; reads: `ref('stg_customers')`

The changed object is the CTE `base` inside `dim_customers.sql`. CTEs are scoped to the SQL statement they appear in — they are not referenceable by other files and do not appear as nodes in the dependency graph.

Seed: CTE `base` (internal to `dim_customers.sql`) — not a graph node

## Impact tree

```
dim_customers.sql :: CTE `base` (CHANGED — internal)
└── (no external consumers — CTEs are not referenceable outside their SQL statement)
```

## Consumer details

No external consumers found. The CTE `base` is referenced only within `dim_customers.sql` itself:
- Line 1: `with base as (` — ASSIGNMENT (CTE definition)
- Line 8: `select * from base` — internal SELECT (final statement of the same SQL file)

Both references are inside the same file and the same SQL statement scope.

## Summary
- Total impacted: 0 external files
- Direct consumers: 0
- Transitive consumers: 0
- Silent propagation (SELECT *): 0
- Stacks affected: none externally
- Max impact tree depth: 0
- This change is safe — no consumer coordination required
- Cross-repo consumers: not applicable (CTE names are not externally visible)

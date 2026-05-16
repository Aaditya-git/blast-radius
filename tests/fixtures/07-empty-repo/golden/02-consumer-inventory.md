# Stage 2 — Consumer Inventory

## ⚠️ No consumers found in scope. This does NOT imply safety.

Verify that the search scope is correct and consider:
- Whether cross-repo consumers exist (external services, shared libraries, BI tools)
- Whether the table is queried directly by tools outside this repo (notebooks, SQL clients, ML platforms)
- Broadening the scope to include additional directories

## Dependency graph construction
Scanned all files in `tests/fixtures/07-empty-repo`. Extracted inputs/outputs per file:
- `models/staging/stg_events.sql` → produces: `stg_events`; reads: `source('raw', 'events')`

Seed: `stg_events` (contains changed column `event_type`)

BFS traversal: no files read `stg_events` — adjacency list is empty. Impact set contains only the seed.

## Impact tree

```
stg_events.event_type (CHANGED)
└── (no consumers found in this repo)
```

## Consumer details

None found in this repo.

## Summary
- Total impacted: 0 files
- Direct consumers: 0
- Transitive consumers: 0
- Silent propagation (SELECT *): 0
- Stacks affected: none detected
- Max impact tree depth: 0
- ⚠️ Zero consumers in this repo does NOT mean zero risk. Cross-repo consumers, BI tool connections, ML feature pipelines, and external SQL clients querying this table are outside this search scope. Verify before deploying.
- Cross-repo consumers: not visible in this search — verify separately

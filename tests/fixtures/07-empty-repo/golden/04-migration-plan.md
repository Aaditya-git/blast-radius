# Stage 4 — Migration Plan

## Strategy: hard cut (conditional)

No will-break consumers were identified in this repo. If cross-repo consumers are also ruled out (see Stage 3 notes), a hard cut is appropriate.

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | Verify no cross-repo consumers exist | Day 0 | Unknown |
| Phase 2 | Rename `event_type` → `event_category` in `stg_events` | Day 0 | Unknown |
| Phase 3 | Run dbt compile to verify | Day 0 | Unknown |

## Per-consumer migration steps

None identified in this repo.

## Rollback triggers

- Any downstream system reports missing column `event_type` after deployment
- Any pipeline failure referencing `event_type`

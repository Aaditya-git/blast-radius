# Stage 4 — Generate migration plan

## Input
- The change classification (Stage 1)
- The consumer inventory (Stage 2)
- The risk assessment (Stage 3)

## What to do

### Choose a strategy

Pick one based on severity and consumer count:

| Situation | Strategy |
|---|---|
| Zero will-break consumers | Hard cut — change is safe to deploy directly |
| 1-3 will-break consumers, all in same project | Coordinated update — change source and all consumers in one PR |
| 4+ will-break consumers OR cross-team consumers | Deprecation window with dual columns/tables — old + new coexist for N days |
| Semantic change (meaning shift, not rename) | Versioned alias — `metric_v2` exists alongside `metric`; consumers migrate at their own pace |
| Type change that may silently corrupt data | Dual-write with explicit validation period |

### Build the timeline

Each phase has: action, day, owner. Use working days from Day 0 (PR merge).

Standard deprecation window phases:
- **Day 0:** add new alongside old
- **Day 1:** update internal consumers
- **Day 2-13:** deprecation window (external consumers migrate)
- **Day 14:** remove old

For coordinated updates (small blast radius), collapse to:
- **Day 0:** change source + all consumers in one PR

### Specify rollback triggers

List the observable signals that should abort the migration:
- Pipeline compile failures
- Data quality test failures on the new column
- Stakeholder report of changed numbers downstream
- Any will-break consumer that did not migrate by deadline

### Per-consumer migration steps

List each will-break consumer from Stage 2 and the specific edit each one needs.

## Output

Write artifact to `docs/data-changes/<slug>/04-migration-plan.md`.

Structure:

```markdown
# Stage 4 — Migration Plan

## Strategy: <chosen strategy>

<one paragraph: why this strategy fits the severity + consumer count>

## Timeline

| Phase | Action | Day | Owner |
|---|---|---|---|
| Phase 1 | <action> | Day 0 | <owner> |
| ... | ... | ... | ... |

## Per-consumer migration steps

1. `<file>` — <specific edit>
2. ...

## Rollback triggers

- <signal 1>
- <signal 2>
- ...
```

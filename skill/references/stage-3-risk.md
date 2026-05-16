# Stage 3 — Assess risk

## Input
- The consumer inventory from Stage 2

## What to do

For each consumer in the inventory, score three dimensions.

### Criticality
- **Production** — path contains `prod`, `production`, `marts/` (typically prod in dbt), `main/`
- **Staging** — path contains `staging`, `stg/`, `dev`
- **Dev** — path contains `sandbox`, `experimental`, `scratch`
- **Documentation** — schema.yml or markdown
- **Unknown** — no environmental hints

### Severity
Based on the **Usage** and **Break classification** fields from Stage 2:
- **Will-break** — SELECT, WHERE, JOIN usages of a renamed/dropped column; also any orchestration node (Airflow DAG, Prefect flow, cron job) that executes a will-break callable — the DAG *runs* the broken pipeline, so it breaks too
- **Will-break (runtime)** — Python, Spark, or notebook consumers: no compile-time error, but will fail at runtime when the column is not found; flag explicitly so the team knows the failure is deferred
- **May-break** — usage in a comment, conditional, or context that may or may not be hit at runtime
- **Will-go-stale** — schema docs, README references, or config values that name the old column but do not execute code (no runtime failure, but documentation or config drifts from reality)
- **Safe** — comment-only or unrelated coincidental match

### Owner
- Check `CODEOWNERS` (root or `.github/CODEOWNERS`) — match by path
- If no CODEOWNERS, attempt `git log -1 --format='%an' -- <path>` for last author
- If neither works → `Unknown`

## Output

Write artifact to `docs/data-changes/<slug>/03-risk-assessment.md`.

Structure:

```markdown
# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| <file> | <crit> | <sev> | <owner> |

## Notes
- <any cross-cutting observations>
```

Sort the table: production + will-break at top, documentation + will-go-stale at bottom.

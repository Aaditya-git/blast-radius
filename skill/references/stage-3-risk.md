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
Based on the **Usage** field from Stage 2:
- **Will-break** — SELECT, WHERE, JOIN usages of a renamed/dropped column or table
- **May-break** — usage in a comment, conditional, or context that may or may not be hit
- **Will-go-stale** — schema docs that reference the old name (no compile failure but documentation drift)
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

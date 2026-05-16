---
name: blast-radius
description: Use when a user is about to make a breaking change to data transformations (rename column, drop model, change grain, alter metric definition) — traces all downstream consumers across dbt, SQL, Python, notebooks, and orchestration code, then produces a migration plan and stakeholder comms.
---

# blast-radius

When the user signals intent to make a breaking change to a data transformation, walk through five disciplined stages. Each stage produces one Markdown artifact in `docs/data-changes/<YYYY-MM-DD>-<change-slug>/`.

## When this skill activates

ACTIVATE when the user:
- Mentions renaming, dropping, or altering a column, table, dbt model, or pipeline output
- Asks "what depends on X" or "what will break if I change Y"
- Says "blast radius," "breaking change," "impact analysis," "downstream consumers"

DO NOT activate for:
- Consumer-side reads (querying data without changing it)
- Internal refactors that do not change outputs
- Bug fixes that do not change schema or semantics

## Workflow checklist

Before starting, confirm with the user:
1. What is the change? (object + before/after)
2. What is the slug for this change? (e.g., `rename-customer-age`)
3. Where is the repo root? (default: current working directory)
4. Dry run? (if the user says "dry run," print artifacts to the session instead of writing them to disk)

Then create the change folder:
`docs/data-changes/<YYYY-MM-DD>-<change-slug>/`

Run the stages in order. Pause after each stage and ask the user "continue?" before proceeding.

- [ ] Stage 1 — Classify the change. Read `references/stage-1-classify.md`.
- [ ] Stage 2 — Trace consumers. Read `references/stage-2-trace.md`.
- [ ] Stage 3 — Assess risk. Read `references/stage-3-risk.md`.
- [ ] Stage 4 — Generate migration plan. Read `references/stage-4-migrate.md`.
- [ ] Stage 5 — Draft stakeholder comms. Read `references/stage-5-comms.md`.

## Transparency requirements

- Announce each stage start: `## Stage N — <title>`.
- Print every search before running it: `Searching for 'X' in *.sql, *.py, *.yml, *.ipynb`.
- Print every classification with reasoning: `BREAKING — column renamed with no compatibility shim`.
- Final summary lists scope searched vs. consumers found.

## Failure modes

- Zero consumers found → flag prominently, suggest broadening scope, do NOT imply safety
- File parse fails → mark as "manual review required" in the inventory, continue
- Ambiguous change intent → ask ONE clarifying question, do not guess
- Cross-repo dependencies → flag as out of scope, note in inventory

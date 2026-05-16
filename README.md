# blast-radius

A Claude Code skill that traces the full impact of breaking data changes — across dbt, SQL, Python, notebooks, and orchestration code — and generates a migration plan and stakeholder communications.

## The problem

Breaking changes to data (column renames, model removals, grain changes, metric redefinitions) silently corrupt downstream dashboards, ML features, and reports. No existing tool traces blast radius across all the layers a data system spans. `blast-radius` does.

## What it does

Invoke the skill when you're about to make a breaking change. Claude walks through five disciplined stages:

1. **Classify** — categorizes the change (structural / semantic / infrastructural; breaking / additive / safe)
2. **Trace** — greps and parses the repo to find every downstream consumer across dbt, raw SQL, Python, notebooks, and Airflow YAML
3. **Assess** — scores each consumer by criticality (prod / staging / dev), severity (will-break / may-break / stale), and owner
4. **Plan** — generates a concrete migration strategy (hard cut / coordinated update / deprecation window / versioned alias)
5. **Communicate** — drafts ready-to-send Slack messages, PR description, and changelog entry

Each stage produces a Markdown artifact in `docs/data-changes/<YYYY-MM-DD>-<change-slug>/` so the work is fully transparent, reviewable in PRs, and forms a permanent audit trail.

## Quick start

```
# Install (one time)
cp -r skill/ ~/.claude/skills/blast-radius/

# Invoke
# In a Claude Code session on your repo:
> Use the blast-radius skill. I want to rename customer_age to customer_age_years in stg_customers.
```

Claude will confirm the change details, then run all five stages with a "continue?" pause between each.

## Stack coverage (v1)

| Stack | What it searches |
|---|---|
| dbt | `ref()`, `source()`, `schema.yml` column docs |
| Raw SQL | `FROM`, `JOIN`, `SELECT` in `.sql` files |
| Python | `pd.read_sql`, `spark.read.table`, SQL strings in `.py` |
| Notebooks | SQL strings in `.ipynb` code cells |
| Airflow YAML | DAG configs referencing tables or columns |

## Design principles

- **Zero config** — works on any repo without setup or instrumentation
- **Transparent** — every search is announced; every classification shows its reasoning
- **Errs toward over-reporting** — false positives are cheap; false negatives are catastrophic
- **Stage-independent** — invoke a single stage when that's all you need

## Install

See [INSTALL.md](INSTALL.md).

## Spec and plan

- Design spec: [`docs/superpowers/specs/2026-05-15-blast-radius-design.md`](docs/superpowers/specs/2026-05-15-blast-radius-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-05-15-blast-radius.md`](docs/superpowers/plans/2026-05-15-blast-radius.md)

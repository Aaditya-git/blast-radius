# blast-radius

A Claude Code skill that traces the full impact of breaking data changes — across dbt, SQL, Python, notebooks, and orchestration code — and generates a migration plan and stakeholder comms.

## Status

Early design phase. The design spec lives at [`docs/superpowers/specs/2026-05-15-blast-radius-design.md`](docs/superpowers/specs/2026-05-15-blast-radius-design.md).

## The problem

Breaking changes to data (column renames, model removals, grain changes, metric redefinitions) silently corrupt downstream dashboards, ML features, and reports. No existing tool traces blast radius across all the layers a data system spans. `blast-radius` does.

## What it does

When invoked, the skill walks Claude through five disciplined stages:

1. **Classify** the change (structural / semantic / infrastructural; breaking / additive / safe)
2. **Trace** every consumer across the codebase
3. **Assess** risk per consumer
4. **Generate** a migration plan
5. **Draft** stakeholder communications

Each stage produces a Markdown artifact in `docs/data-changes/<date>-<slug>/` so the work is fully transparent and reviewable in PRs.

## Design principles

- **Easy to use** — one-line invocation, zero config
- **Transparent** — every stage produces an inspectable artifact
- **Scalable** — works on small repos and large monorepos
- **Stage-independent** — invoke any single stage standalone

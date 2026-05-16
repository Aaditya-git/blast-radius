# blast-radius

A Claude Code skill that traces the full blast radius of breaking data changes through **transitive lineage traversal** — finding every impacted consumer across every stack, including those that never mention the changed column by name.

## The problem

Breaking changes to data (column renames, model removals, grain changes, metric redefinitions) silently corrupt downstream dashboards, ML features, and reports. The hard part isn't finding direct consumers — a grep can do that. The hard part is finding the full chain:

```
stg_customers.customer_age renamed
└── dim_customers [dbt] — direct consumer                ← grep finds this
    └── revenue_pipeline.py [Python] — reads dim_customers  ← grep misses this
        └── daily_dag.yml [Airflow] — triggers the pipeline    ← grep misses this
            └── exec_dashboard [downstream] — reads the output    ← grep misses this
```

No existing tool traces blast radius across all the layers a data system spans. `blast-radius` does.

## What it does

Invoke the skill when you're about to make a breaking change. Claude walks through five disciplined stages:

1. **Classify** — categorizes the change (structural / semantic / infrastructural; breaking / additive / safe)
2. **Trace** — builds a full dependency graph of the repo, then traverses it to find every impacted consumer at every depth — direct and transitive, across every file type
3. **Assess** — scores each consumer by criticality (prod / staging / dev), severity (will-break / silent-propagation / transitive-risk), and owner
4. **Plan** — generates a concrete migration strategy (hard cut / coordinated update / deprecation window / versioned alias)
5. **Communicate** — drafts ready-to-send Slack messages, PR description, and changelog entry

Each stage produces a Markdown artifact in `docs/data-changes/<YYYY-MM-DD>-<change-slug>/` — committed, visible in PRs, permanent audit trail.

## How Stage 2 works (the core)

Stage 2 is not a grep. It builds a dependency graph first:

1. **Graph construction** — scan every file in the repo, extract what each file reads and what it produces, build an adjacency map
2. **Seed** — add the changed object to the impact set
3. **BFS traversal** — walk forward: any file that reads from an affected output is also affected, at every depth
4. **Classify** — DIRECT (depth 1) vs TRANSITIVE (depth 2+), WILL-BREAK vs SILENT-PROPAGATION vs TRANSITIVE-RISK

Output is an impact tree, not a flat list:

```
stg_customers.customer_age (CHANGED)
└── dim_customers.sql [dbt] — DIRECT — WILL-BREAK
    └── extract_age_features.py [Python] — TRANSITIVE depth 2 — WILL-BREAK
        └── customer_features_dag.yml [Airflow] — TRANSITIVE depth 3 — TRANSITIVE-RISK
```

## Stack coverage (universal)

Every file type in the repo is analyzed — not just a predefined list of extensions.

| Stack | How dependencies are extracted |
|---|---|
| dbt | `ref('model')`, `source('db', 'table')` → model name = filename |
| Raw SQL | `FROM`, `JOIN` table names; `CREATE VIEW/TABLE` as output |
| Python | `spark.read.table`, `pd.read_sql`, SQLAlchemy, raw SQL strings; `saveAsTable`, `to_sql` as outputs |
| Notebooks | same as Python, parsed from code cells |
| Airflow YAML / Python DAGs | `sql:`, `source_table:`, `op_kwargs` table refs; `target_table:` as output |
| TypeScript / JavaScript | Knex `.from()`, Prisma models, template SQL strings |
| Java / Kotlin | JDBC strings, Hibernate `@Table`, JPA `@Query` |
| Go | `db.Query`, GORM `.Table()` |
| Ruby | ActiveRecord `from()`, `joins()`, raw SQL |
| Config files | `table:`, `source_table:`, `dataset:`, `entity:` keys |

## Quick start

```bash
# Install (one time)
cp -r skill/ ~/.claude/skills/blast-radius/
```

Then open Claude Code in any repo and describe what you want to change:

```
> Use the blast-radius skill. I want to rename customer_age to customer_age_years in stg_customers.
```

Claude confirms the change, builds the dependency graph, traverses it, and walks through all five stages with a "continue?" pause between each.

## Design principles

- **Zero config** — works on any repo without setup or instrumentation
- **Transitive by default** — finds what grep misses; the impact tree shows the full propagation chain
- **Universal** — every file type in the repo, not a fixed list of extensions
- **Transparent** — every graph construction step is announced; every classification shows its reasoning
- **Errs toward over-reporting** — false positives are cheap; false negatives are catastrophic
- **Stage-independent** — invoke a single stage when that's all you need

## Install

See [INSTALL.md](INSTALL.md).

## Spec and plan

- Design spec: [`docs/superpowers/specs/2026-05-15-blast-radius-design.md`](docs/superpowers/specs/2026-05-15-blast-radius-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-05-15-blast-radius.md`](docs/superpowers/plans/2026-05-15-blast-radius.md)

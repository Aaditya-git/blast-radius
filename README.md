# blast-radius

A Claude Code skill that traces the full blast radius of breaking data changes through **transitive lineage traversal** — finding every impacted consumer across every stack, including those that never mention the changed column by name.

## The problem

Breaking changes to data (column renames, model removals, grain changes, metric redefinitions) silently corrupt downstream dashboards, ML features, and reports. The hard part isn't finding direct consumers — a grep can do that. The hard part is finding the full chain:

```
stg_customers.customer_age renamed
└── dim_customers [dbt] — DIRECT consumer              ← grep finds this
    └── revenue_pipeline.py [Python]                   ← grep misses this
        └── daily_dag.yml [Airflow]                    ← grep misses this
            └── exec_dashboard [downstream]            ← grep misses this
```

No existing tool traces blast radius across all the layers a data system spans. `blast-radius` does.

## What it does

Invoke the skill when you're about to make a breaking change. Claude walks through five disciplined stages:

| Stage | Output |
|---|---|
| 1. Classify | Change kind (structural / semantic / infrastructural), severity (breaking / additive / safe), surface |
| 2. Trace | Full dependency graph → BFS traversal → impact tree at every depth, across every file type |
| 3. Assess | Each consumer scored: criticality (prod / staging / dev), severity (will-break / silent-propagation / transitive-risk), owner |
| 4. Plan | Concrete migration strategy with exact file/line edits, rollback triggers, timeline |
| 5. Communicate | Ready-to-send Slack message, PR description, changelog entry |

Each stage produces a Markdown artifact committed to `docs/data-changes/<YYYY-MM-DD>-<change-slug>/` — visible in PRs, permanent audit trail.

## Real example: Jaffle Shop

Running blast-radius against the real [dbt-labs/jaffle-shop](https://github.com/dbt-labs/jaffle-shop) repo on a `customer_name → full_name` column rename:

**What `grep -r customer_name models/` finds:**
```
models/staging/stg_customers.sql:17:  name as customer_name
models/marts/customers.yml:13:    - name: customer_name
models/marts/customers.yml:45:      - name: customer_name
```

**What blast-radius finds:**

```
stg_customers.customer_name (CHANGED → full_name)
└── customers.sql [dbt] — DIRECT — SILENT-PROPAGATION (SELECT *)
    └── customers.yml [dbt doc + MetricFlow] — TRANSITIVE depth 2
        ├── line 45: WILL-BREAK (MetricFlow dimension fails at query time)
        └── line 13: WILL-GO-STALE (column doc becomes factually wrong)
```

`customers.sql` contains `select * from {{ ref('stg_customers') }}` — the rename propagates invisibly through the SELECT \*, silently changing the output schema of the `customers` mart. **Completely invisible to grep.** Any BI dashboard or ML pipeline reading `customers.customer_name` breaks post-deploy with no compile-time warning.

See [`tests/runs/jaffle-shop/`](tests/runs/jaffle-shop/) for the full five-stage output.

## How Stage 2 works (the core)

Stage 2 is not a grep. It builds a dependency graph first:

1. **Graph construction** — scan every file in the repo, extract what each file reads and produces, build an adjacency map
2. **Seed** — add the changed object to the impact set
3. **BFS traversal** — walk forward: any file that reads from an affected output is also affected, at every depth
4. **Classify** — DIRECT (depth 1) vs TRANSITIVE (depth 2+); WILL-BREAK vs SILENT-PROPAGATION vs TRANSITIVE-RISK

## Stack coverage

Every file type in the repo is analyzed — not a predefined list of extensions.

| Stack | How dependencies are extracted |
|---|---|
| dbt | `ref('model')`, `source('db', 'table')` |
| Raw SQL | `FROM`, `JOIN`, `CREATE VIEW/TABLE` |
| Python | `spark.read.table`, `pd.read_sql`, SQLAlchemy, raw SQL strings |
| Notebooks | Same as Python, parsed from code cells |
| Airflow | `sql:`, `source_table:`, `op_kwargs` table refs |
| TypeScript / JS | Knex `.from()`, Prisma models, template SQL |
| Java / Kotlin | JDBC strings, Hibernate `@Table`, JPA `@Query` |
| Go | `db.Query`, GORM `.Table()` |
| Ruby | ActiveRecord `from()`, `joins()`, raw SQL |
| Config files | `table:`, `source_table:`, `dataset:`, `entity:` keys |

## Quick start

```bash
# Install (one time)
claude plugins install github:Aaditya-git/blast-radius
```

Open Claude Code in your repo:

```
> Use the blast-radius skill. I want to rename customer_age to customer_age_years in stg_customers.
```

Or trigger it implicitly:
- *"what depends on this model?"*
- *"blast radius of dropping orders_v1"*
- *"what will break if I change the grain of dim_customers?"*

Claude confirms the change, builds the dependency graph, and walks through all five stages. After each stage it pauses and asks "continue?" — you can stop, edit the artifact, or rerun a stage.

Artifacts are written to:
```
docs/data-changes/<YYYY-MM-DD>-<change-slug>/
├── 01-change-classification.md
├── 02-consumer-inventory.md
├── 03-risk-assessment.md
├── 04-migration-plan.md
└── 05-stakeholder-comms.md
```

## Design principles

- **Zero config** — works on any repo without setup or instrumentation
- **Transitive by default** — finds what grep misses; the impact tree shows the full propagation chain
- **Universal** — every file type, not a fixed extension list
- **Transparent** — every graph construction step is announced; every classification shows its reasoning
- **Errs toward over-reporting** — false positives are cheap; false negatives are catastrophic
- **Stage-independent** — invoke a single stage when that's all you need

## Repo layout

```
skills/                     ← installed automatically via claude plugins install
  SKILL.md                  ← skill entry point and workflow
  references/
    stage-1-classify.md
    stage-2-trace.md
    stage-3-risk.md
    stage-4-migrate.md
    stage-5-comms.md
tests/
  fixtures/                 ← 7 test scenarios with golden artifacts
    01-dbt-rename/
    02-python-consumer/
    03-notebook-consumer/
    04-grain-change/
    05-safe-refactor/
    06-ambiguous-intent/
    07-empty-repo/
  runs/                     ← actual skill output for each scenario
    jaffle-shop/            ← real-world validation run
```

## Disabling blast-radius

**Skip a single run** — when Claude asks "continue?" at any stage, say "stop" to halt the workflow immediately.

**Disable for a specific project** — add this line to the project's `CLAUDE.md`:
```
Do not use the blast-radius skill in this project.
```

**Disable globally for a session** — tell Claude at the start of the conversation:
```
Disable blast-radius for this session.
```

**Uninstall completely:**
```bash
# If installed via claude plugins
claude plugins uninstall blast-radius

# If installed manually
rm -rf ~/.claude/skills/blast-radius
```

## Installation

See [INSTALL.md](INSTALL.md) for full install and usage options including dry run and single-stage modes.

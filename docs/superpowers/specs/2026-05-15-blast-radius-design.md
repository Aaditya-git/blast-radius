# blast-radius — Design Spec

**Date:** 2026-05-15
**Status:** Draft (awaiting user review)

## What this is

A Claude Code skill that orchestrates the full workflow for breaking data changes. When a data engineer is about to rename a column, drop a model, change a grain, or alter the meaning of a metric, this skill makes Claude walk through five disciplined stages — classify the change, trace every consumer across the codebase, assess risk, generate a migration plan, and draft stakeholder communications.

## The problem

At production scale, breaking changes to data are catastrophically expensive when mishandled. A column rename can silently corrupt every downstream dashboard, ML feature, and report for weeks before anyone notices. The reason: **no existing tool traces blast radius across all the layers a data system actually spans** — dbt, raw SQL, Python pipelines, Spark jobs, BI tools, notebooks, ML feature stores, orchestration configs, and external APIs.

Current state of the art:
- **dbt lineage** — only sees inside dbt
- **Data catalogs** (Atlan, DataHub, Alation) — require heavy instrumentation, lineage goes stale
- **Datafold** — closest competitor, but dbt-only, paid, requires cloud integration
- **Manual grep** — slow, error-prone, misses dynamic references
- **Deploy and see what breaks** — embarrassingly common

No Claude Code skill exists for this. The Impact Analyzer on MCP Market is a general-purpose code dependency tracer — it does not understand data semantics (grain changes, metric definitions, downstream BI/ML consumers without traditional code dependencies).

## Why a skill, not a tool

A skill works on day one with zero config. It reads the codebase that's already there. It requires no instrumentation, no cloud integration, no pricing tier. The engineer says "I want to rename column X to Y" and the skill takes over.

## Design principles

1. **Easy to use.** One-line invocation. No flags, no config for normal use.
2. **Transparent.** Every stage produces a visible Markdown artifact. The engineer sees exactly what was searched, what was found, and why each classification was made.
3. **Scalable.** Works on a 50-file repo and a 10,000-file monorepo without choking. Search is bounded, parsing is lazy, results stream.
4. **Stage-independent.** Engineers can run just one stage (e.g., trace consumers) without committing to the full workflow.
5. **Pragmatic.** Errs on the side of flagging too many consumers rather than too few. False positives are cheap; false negatives are catastrophic.

---

## Architecture

### Skill shape

Packaged as a directory skill following the superpowers convention:

```
skill/
├── SKILL.md                      # entry point: frontmatter, activation rules, top-level checklist
├── references/
│   ├── stage-1-classify.md       # detailed instructions for change classification
│   ├── stage-2-trace.md          # search patterns for each stack (dbt, sql, python, etc.)
│   ├── stage-3-risk.md           # risk scoring rubric
│   ├── stage-4-migrate.md        # migration strategy decision tree
│   └── stage-5-comms.md          # communication templates
└── README.md                     # install + usage for end users
```

`SKILL.md` is loaded on activation. Reference files are read on demand by Claude as each stage runs, keeping the upfront load cheap.

### Activation

The skill activates when the user signals intent to make a breaking change to data transformations. Triggers include:

- Explicit invocation: "use the blast-radius skill"
- Phrases like "blast radius," "breaking change," "what depends on…"
- Stated intent to rename / drop / alter a dbt model, SQL transformation, schema, or data pipeline

The skill MUST NOT activate for:
- Pure consumer-side changes (reading data, not producing it)
- Internal-only refactors that don't change outputs
- Bug fixes that don't change schema or semantics

### Output location

Artifacts are written to `docs/data-changes/<YYYY-MM-DD>-<change-slug>/` in the user's repo. Visible and committed so they:
- Show up automatically in PRs
- Are reviewable by stakeholders without checking out the branch
- Form a permanent audit trail of breaking changes

Folder structure per change:
```
docs/data-changes/2026-05-15-rename-customer-age/
├── 01-change-classification.md
├── 02-consumer-inventory.md
├── 03-risk-assessment.md
├── 04-migration-plan.md
└── 05-stakeholder-comms.md
```

---

## The five workflow stages

### Stage 1 — Classify the change

**Input:** a diff, change description, or user's stated intent.

**What Claude does:** Categorizes the change along three axes:
- **Kind:** structural (column/table rename, type change), semantic (logic change, definition change), infrastructural (location, format, frequency)
- **Severity:** breaking, additive, safe
- **Surface:** column / table / model / pipeline / schema

**Artifact:** `01-change-classification.md` — what is changing, the category, and the reasoning for the classification.

### Stage 2 — Trace consumers

**Input:** the changed object identified in Stage 1.

**What Claude does:** Searches the codebase using stack-specific patterns.

**v1 stack coverage:**

| Stack | Patterns | Priority |
|---|---|---|
| dbt | `ref('model')`, `source('db', 'table')`, `schema.yml` | v1 |
| Raw SQL | direct table refs in `.sql` files (FROM/JOIN/INTO) | v1 |
| Python | `pd.read_sql`, `spark.read.table`, SQLAlchemy ORM, raw SQL strings | v1 |
| Notebooks | SQL strings in `.ipynb` code cells | v1 |
| Orchestration | Airflow DAGs, Prefect flows, YAML configs | v1 |
| BI tools | LookML, Tableau XML, Metabase JSON | v2 (each needs its own parser) |
| Dagster | asset graph | v2 |

Search strategy is two-phase:
1. **Fast grep** for the literal table/column name across the repo
2. **Targeted parse** for each hit, using the right parser for the file type, to extract usage context (SELECT vs. WHERE vs. JOIN vs. assignment)

**Artifact:** `02-consumer-inventory.md` — each consumer with file path, line number, snippet, detected stack, and usage context.

### Stage 3 — Assess risk

**Input:** the consumer inventory from Stage 2.

**What Claude does:** For each consumer, scores three dimensions:
- **Criticality:** production / staging / dev / unknown — inferred from path (`prod/`, `staging/`), naming (`_prod_`, `_dev_`), or environment config
- **Break severity:** will-break / may-break / safe — based on how the column/table is used (e.g., renamed column referenced in SELECT = will-break; only in a comment = safe)
- **Owner:** inferred from `CODEOWNERS`, git blame on the file, or marked unknown

**Artifact:** `03-risk-assessment.md` — risk matrix sorted by severity (will-break + production at the top).

### Stage 4 — Generate migration plan

**Input:** the change + risk assessment.

**What Claude does:** Builds a concrete rollout plan:
- **Strategy choice:** versioned alias (`column_v2`), dual-write, deprecation window, hard cut — picked based on risk level
- **Timeline:** deprecation start, dual-write period, removal date
- **Rollback triggers:** what to watch for, when to abort
- **Per-consumer migration steps:** ordered by criticality

**Artifact:** `04-migration-plan.md`.

### Stage 5 — Draft stakeholder communications

**Input:** the migration plan + consumer owners.

**What Claude does:** Drafts ready-to-send messages targeted by audience:
- Slack message templates grouped by team
- Email for formal notifications
- PR description template that links the artifacts
- Deprecation notice for the project changelog or docs site

**Artifact:** `05-stakeholder-comms.md`.

---

## Data flow

```
User states intent  →  Skill activates  →  Stage 1 → artifact written → pause for OK
                                          → Stage 2 → artifact written → pause for OK
                                          → Stage 3 → artifact written → pause for OK
                                          → Stage 4 → artifact written → pause for OK
                                          → Stage 5 → artifact written → done
```

- Each stage reads the previous stage's artifact as input
- Stages can be invoked independently — `stage-2 only` is valid for "just tell me who depends on this"
- Claude pauses after each stage and asks "continue?" — engineer has full control to stop, edit the artifact, or rerun

### Scalability mechanics

- **Grep before parse.** Never parse a file that grep didn't hit.
- **Stream results.** Stage 2 writes consumers to the inventory as they are found, not at the end.
- **Cached parses within a session** so multi-stage runs do not re-parse the same file.
- **Bounded scope.** Defaults to the repo root with sensible excludes (`node_modules`, `.venv`, `dist`, `build`, `.git`). Optional `--scope` for monorepos to constrain the search.

### Transparency mechanics

- Every stage prints a header: `## Stage 2 — Tracing consumers`
- Every search prints what it's looking for: `Searching for 'customer_age' in *.sql, *.py, *.yml, *.ipynb...`
- Every classification prints the reasoning: `Classified BREAKING — column renamed, no compatibility shim`
- Final summary table shows scope searched vs. results found

---

## Error handling

| Failure | Behavior |
|---|---|
| Search yields zero consumers | Surface "no consumers found" prominently. Suggest broadening scope. Do not assume safety silently. |
| File parse fails (e.g., malformed SQL) | Log the file as "parse failed — manual review required" in the inventory. Continue with other files. |
| Ambiguous change intent (Claude can't classify) | Stage 1 asks the user one clarifying question rather than guessing. |
| User aborts mid-workflow | Artifacts produced so far remain on disk. The folder is a checkpoint — the user can resume by invoking a later stage. |
| Cross-repo consumers (out of scope) | Flag in the inventory: "Consumers in this repo only. Cross-repo dependencies may exist — verify separately." |
| Conflicting risk signals | Stage 3 surfaces both signals in the artifact rather than silently picking one. |

The skill errs toward over-reporting. A false positive (flagging a non-issue) is cheap; a false negative (missing a real consumer) is exactly the catastrophic outcome we exist to prevent.

---

## Testing strategy

Two levels, phased.

### Level 1 — Manual fixture-based testing (v1 mandatory)

A `tests/fixtures/` directory contains miniature repos representing common stacks:
- `dbt-project/` — small dbt repo with models, sources, schema.yml
- `python-pipelines/` — Python files using pandas/Spark to read tables
- `notebook-consumer/` — Jupyter notebook with SQL strings
- `airflow-dags/` — sample Airflow DAG referencing tables
- `mixed/` — combination of all of the above
- `empty-repo/` — sanity case: skill should report zero consumers clearly

A human invokes the skill against each fixture and verifies the artifacts are correct and useful.

### Level 2 — Automated behavioral testing (v2)

A test harness script invokes Claude with the skill loaded (via Anthropic SDK), saves the produced artifacts, and diffs them against a `golden/` directory of expected outputs. Allows prose variation but checks structured fields (consumer count, severity classifications, file paths). Deferred until skill behavior is stable.

### Base test cases (must pass in v1)

| # | Scenario | What it tests |
|---|---|---|
| 1 | Column rename in a dbt model with only dbt consumers | Basic dbt ref tracing |
| 2 | Column drop in a SQL table, Python pipeline reads it | Cross-stack detection |
| 3 | Model removal with notebook consumer | Notebook scanning |
| 4 | Grain change in a fact table | Semantic classification (not just structural) |
| 5 | No-op refactor (variable rename internal to a model) | No false alarms on non-breaking changes |
| 6 | Ambiguous intent ("change the customer table") | Skill asks a clarifying question instead of guessing |
| 7 | Zero consumers found | Skill flags clearly rather than implying safety |

### Real-world validation milestones

- Hand-run the skill against a public open-source dbt project (e.g., a Jaffle Shop variant) to confirm output usefulness on real code.
- Dogfood on the user's own projects before publishing.

---

## Resolved design decisions

- **v1 is pure Markdown.** The skill is a directory of Markdown files. No custom parsers, no install step, no runtime dependencies. Claude does the work using tools already available in a Claude Code session (grep, Read, file reads, ad-hoc Bash). If during testing we find Claude can't reliably handle a class of input (e.g., complex SQL CTEs), we add a thin helper script in v2 — not before.
- **Dry-run mode (v1):** Yes. A `--dry-run` flag runs all stages and prints to stdout without writing artifacts. Useful for first-time users exploring what the skill does.
- **Artifact code references:** Each artifact references changed code by file path + git SHA + line numbers, not by embedding diffable snapshots. Keeps artifacts small and survivable across rebases.
- **v1 stack parsers:** dbt, raw SQL, Python, notebooks, Airflow YAML. BI tools and Dagster move to v2 (each needs a dedicated parser).
- **Testing approach:** Manual fixture-based validation for v1. Automated behavioral harness (Anthropic SDK + golden-file diff) deferred to v2 once skill behavior is stable.

## Out of scope (v1)

- Cross-repo blast radius (would require multi-repo indexing — defer)
- Runtime lineage from query logs (would require infra integration)
- Automatic migration execution (this skill plans; humans execute)
- BI tool config parsing (LookML / Tableau / Metabase — deferred to v2)
- Versioning of the artifacts themselves (git handles that)

---

## Distribution

1. **Phase 1:** Standalone GitHub repo. Users clone or copy `skill/` into `~/.claude/skills/`.
2. **Phase 2:** Once validated against real projects, publish to MCP Market and superpowers community.
3. **Phase 3:** Consider an npm-distributed installer (similar to `cc-catalyst`) for one-command install.

## Success criteria

- A data engineer can run the full workflow on a real breaking change in under 5 minutes.
- The consumer inventory finds every consumer that a hand search would find, in at least 95% of test cases.
- The migration plan is usable as-is for at least 80% of breaking changes (no manual rewriting required).
- The stakeholder comms drafts are sendable with minor edits (no rewriting from scratch).
- Zero-config install: cloning the repo and dropping `skill/` into `~/.claude/skills/` is the only setup required.

# blast-radius Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code skill that traces blast radius of breaking data changes across dbt, raw SQL, Python, notebooks, and Airflow YAML — producing five inspectable Markdown artifacts (classification, consumer inventory, risk, migration plan, stakeholder comms).

**Architecture:** Pure-Markdown skill (no executable code in v1). A `SKILL.md` orchestrates five workflow stages; per-stage instructions live in `references/stage-N-*.md`. Claude executes the work using session-native tools (grep, file reads, ad-hoc Bash). Test fixtures are miniature repos in `tests/fixtures/`; each has a `golden/` directory holding the expected artifacts. Validation is manual diff between produced and golden outputs.

**Tech Stack:** Markdown only. No runtime dependencies. Fixtures use realistic file types of each stack (`.sql`, `.py`, `.yml`, `.ipynb`).

**Spec reference:** `docs/superpowers/specs/2026-05-15-blast-radius-design.md`

---

## TDD discipline for a Markdown skill

A Markdown skill has no `pytest`. The discipline is:

1. **Write the golden artifact first** — what should the artifact look like for fixture X?
2. **Write the stage's reference doc** — instructions that make Claude produce that artifact.
3. **Invoke Claude with the skill loaded against the fixture.**
4. **Diff the produced artifact against the golden.** Fix the reference doc until they match (structurally).
5. **Commit.**

This adapts test-first to skill development. The golden file is the test; the reference doc is the implementation.

---

## File structure

```
blast-radius/
├── skill/
│   ├── SKILL.md
│   └── references/
│       ├── stage-1-classify.md
│       ├── stage-2-trace.md
│       ├── stage-3-risk.md
│       ├── stage-4-migrate.md
│       └── stage-5-comms.md
├── tests/
│   ├── README.md
│   ├── run-manual.md           # checklist a human follows to run a fixture
│   └── fixtures/
│       ├── 01-dbt-rename/
│       │   ├── models/...
│       │   ├── change.md       # the proposed change Claude is told about
│       │   └── golden/
│       │       ├── 01-change-classification.md
│       │       ├── 02-consumer-inventory.md
│       │       ├── 03-risk-assessment.md
│       │       ├── 04-migration-plan.md
│       │       └── 05-stakeholder-comms.md
│       ├── 02-python-consumer/
│       ├── 03-notebook-consumer/
│       ├── 04-grain-change/
│       ├── 05-safe-refactor/
│       ├── 06-ambiguous-intent/
│       └── 07-empty-repo/
├── README.md
├── INSTALL.md
└── docs/
    ├── superpowers/
    │   ├── specs/2026-05-15-blast-radius-design.md
    │   └── plans/2026-05-15-blast-radius.md
    └── data-changes/        # where the skill writes artifacts when invoked
```

---

## Phase A — Scaffolding

### Task 1: Create directory structure

**Files:**
- Create: `skill/`, `skill/references/`, `tests/`, `tests/fixtures/`, `docs/data-changes/`

- [ ] **Step 1: Create directories**

```bash
mkdir -p skill/references
mkdir -p tests/fixtures
mkdir -p docs/data-changes
```

- [ ] **Step 2: Add .gitkeep to empty directories**

```bash
touch skill/references/.gitkeep
touch tests/fixtures/.gitkeep
touch docs/data-changes/.gitkeep
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Add skill and tests directory scaffolding"
```

### Task 2: Write SKILL.md skeleton

**Files:**
- Create: `skill/SKILL.md`

- [ ] **Step 1: Create the SKILL.md file with frontmatter and orchestration logic**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skill/SKILL.md
git commit -m "Add SKILL.md skeleton with activation and workflow checklist"
```

---

## Phase B — First vertical slice (fixture 01-dbt-rename)

The goal of this phase: get the skill end-to-end working on the simplest fixture before expanding coverage.

### Task 3: Build fixture 01-dbt-rename

**Files:**
- Create: `tests/fixtures/01-dbt-rename/models/staging/stg_customers.sql`
- Create: `tests/fixtures/01-dbt-rename/models/marts/dim_customers.sql`
- Create: `tests/fixtures/01-dbt-rename/models/marts/fct_orders.sql`
- Create: `tests/fixtures/01-dbt-rename/models/marts/schema.yml`
- Create: `tests/fixtures/01-dbt-rename/dbt_project.yml`
- Create: `tests/fixtures/01-dbt-rename/change.md`

- [ ] **Step 1: Create the dbt project file**

`tests/fixtures/01-dbt-rename/dbt_project.yml`:
```yaml
name: fixture_01
version: '1.0.0'
profile: fixture_01
model-paths: ["models"]
```

- [ ] **Step 2: Create staging model with the column that will be renamed**

`tests/fixtures/01-dbt-rename/models/staging/stg_customers.sql`:
```sql
select
    customer_id,
    first_name,
    last_name,
    customer_age,
    signup_date
from {{ source('raw', 'customers') }}
```

- [ ] **Step 3: Create downstream marts model that uses customer_age**

`tests/fixtures/01-dbt-rename/models/marts/dim_customers.sql`:
```sql
select
    customer_id,
    first_name || ' ' || last_name as full_name,
    customer_age,
    case
        when customer_age < 25 then 'young'
        when customer_age < 60 then 'middle'
        else 'senior'
    end as age_bucket,
    signup_date
from {{ ref('stg_customers') }}
```

- [ ] **Step 4: Create second downstream model that uses customer_age**

`tests/fixtures/01-dbt-rename/models/marts/fct_orders.sql`:
```sql
select
    o.order_id,
    o.customer_id,
    c.customer_age,
    o.order_total,
    o.order_date
from {{ source('raw', 'orders') }} o
join {{ ref('stg_customers') }} c using (customer_id)
```

- [ ] **Step 5: Create schema.yml documenting the columns**

`tests/fixtures/01-dbt-rename/models/marts/schema.yml`:
```yaml
version: 2
models:
  - name: dim_customers
    columns:
      - name: customer_id
      - name: full_name
      - name: customer_age
      - name: age_bucket
      - name: signup_date
  - name: fct_orders
    columns:
      - name: order_id
      - name: customer_id
      - name: customer_age
      - name: order_total
      - name: order_date
```

- [ ] **Step 6: Create the change description (what we tell Claude)**

`tests/fixtures/01-dbt-rename/change.md`:
```markdown
# Proposed change

Rename column `customer_age` to `customer_age_years` in `stg_customers`.

No backward compatibility shim. The old column will no longer exist.
```

- [ ] **Step 7: Commit**

```bash
git add tests/fixtures/01-dbt-rename
git commit -m "Add fixture 01: dbt column rename with two downstream models"
```

### Task 4: Write golden artifacts for fixture 01

**Files:**
- Create: `tests/fixtures/01-dbt-rename/golden/01-change-classification.md`
- Create: `tests/fixtures/01-dbt-rename/golden/02-consumer-inventory.md`
- Create: `tests/fixtures/01-dbt-rename/golden/03-risk-assessment.md`
- Create: `tests/fixtures/01-dbt-rename/golden/04-migration-plan.md`
- Create: `tests/fixtures/01-dbt-rename/golden/05-stakeholder-comms.md`

- [ ] **Step 1: Write golden classification artifact**

`tests/fixtures/01-dbt-rename/golden/01-change-classification.md`:
```markdown
# Stage 1 — Change Classification

## Change summary
Rename column `customer_age` to `customer_age_years` in `stg_customers`.

## Classification

| Axis | Value |
|---|---|
| Kind | Structural |
| Severity | Breaking |
| Surface | Column |

## Reasoning

- **Structural** — the change affects the physical schema (column name), not business semantics
- **Breaking** — the old column will not exist; any consumer referencing `customer_age` will fail to compile or return an error at query time
- **Surface: Column** — the change is scoped to a single column on a single model
```

- [ ] **Step 2: Write golden consumer inventory**

`tests/fixtures/01-dbt-rename/golden/02-consumer-inventory.md`:
```markdown
# Stage 2 — Consumer Inventory

## Search scope
- Repo root: `tests/fixtures/01-dbt-rename`
- Patterns searched: `customer_age` in `*.sql`, `*.py`, `*.yml`, `*.ipynb`
- Files scanned: 4 SQL files, 1 YAML file

## Consumers found

### dim_customers.sql (dbt model)
- **Path:** `models/marts/dim_customers.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (direct reference)
- **Snippet:** `customer_age,`
- **Also:** `models/marts/dim_customers.sql:6-8` references `customer_age` in CASE expression for `age_bucket`

### fct_orders.sql (dbt model)
- **Path:** `models/marts/fct_orders.sql:4`
- **Stack:** dbt
- **Usage:** SELECT (via join)
- **Snippet:** `c.customer_age,`

### schema.yml (dbt schema doc)
- **Path:** `models/marts/schema.yml:7, 14`
- **Stack:** dbt
- **Usage:** column documentation
- **Snippet:** `- name: customer_age` (appears twice — under dim_customers and fct_orders)

## Summary
- Total consumers: 3 files, 5 references
- Stacks affected: dbt only
- No cross-repo dependencies detected (single-repo search)
```

- [ ] **Step 3: Write golden risk assessment**

`tests/fixtures/01-dbt-rename/golden/03-risk-assessment.md`:
```markdown
# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `fct_orders.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `schema.yml` | Documentation | Will-break (stale doc after rename) | Unknown |

## Notes
- Both downstream models reference `customer_age` in SELECT clauses — these will fail at compile time after the rename
- `dim_customers` derives `age_bucket` from `customer_age` — losing the source column also breaks the derived column
- `schema.yml` references will silently go stale; no compile failure but documentation drift
```

- [ ] **Step 4: Write golden migration plan**

`tests/fixtures/01-dbt-rename/golden/04-migration-plan.md`:
```markdown
# Stage 4 — Migration Plan

## Strategy: deprecation window with dual columns

Because all consumers are within the dbt project (no external systems), a deprecation window is feasible and safer than a hard cut.

## Timeline

| Phase | Action | Day |
|---|---|---|
| Phase 1 | Add `customer_age_years` alongside `customer_age` in `stg_customers` | Day 0 |
| Phase 2 | Update `dim_customers` and `fct_orders` to use new column | Day 1 |
| Phase 3 | Update `schema.yml` to add new column docs (keep old marked deprecated) | Day 1 |
| Phase 4 | Run dbt tests; verify both columns return identical values | Day 1 |
| Phase 5 | Mark old column deprecated in schema.yml | Day 2 |
| Phase 6 | Remove `customer_age` from `stg_customers` | Day 14 (after deprecation window) |
| Phase 7 | Remove deprecation docs from `schema.yml` | Day 14 |

## Per-consumer migration steps

1. `dim_customers.sql` — replace 3 references to `customer_age` with `customer_age_years`
2. `fct_orders.sql` — replace 1 reference to `c.customer_age` with `c.customer_age_years`
3. `schema.yml` — replace 2 column name entries

## Rollback triggers

- Any dbt model compile failure after Phase 2
- Any data quality test fails on the new column
- Any stakeholder reports a downstream report showing different numbers
```

- [ ] **Step 5: Write golden stakeholder comms**

`tests/fixtures/01-dbt-rename/golden/05-stakeholder-comms.md`:
```markdown
# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `customer_age` → `customer_age_years` in `stg_customers`.
>
> Affected models: `dim_customers`, `fct_orders`.
>
> Rolling out with a 2-week deprecation window. Old column stays valid until then. Full migration plan in `docs/data-changes/<date>-rename-customer-age/`.
>
> Owners unknown for `dim_customers` and `fct_orders` — if you maintain either, please reply or DM.

## PR description template

```
## Summary
Renames `customer_age` → `customer_age_years` in `stg_customers`.

## Blast radius
- 2 downstream dbt models affected (`dim_customers`, `fct_orders`)
- 1 schema doc to update
- No external (non-dbt) consumers detected

## Rollout
2-week deprecation window. Old column remains valid during this period.

## References
- Migration plan: `docs/data-changes/<date>-rename-customer-age/04-migration-plan.md`
- Risk assessment: `docs/data-changes/<date>-rename-customer-age/03-risk-assessment.md`
```

## Changelog entry

```
### Deprecated
- `stg_customers.customer_age` — renamed to `customer_age_years`. Old name removed on <date + 14 days>.
```
```

- [ ] **Step 6: Commit**

```bash
git add tests/fixtures/01-dbt-rename/golden
git commit -m "Add golden artifacts for fixture 01"
```

### Task 5: Write Stage 1 reference doc

**Files:**
- Create: `skill/references/stage-1-classify.md`

- [ ] **Step 1: Write the Stage 1 reference**

`skill/references/stage-1-classify.md`:
```markdown
# Stage 1 — Classify the change

## Input
- The user's stated change (object + before/after)
- Optionally: a diff or PR description

## What to do

1. Determine the **Kind** of change:
   - **Structural** — affects physical schema (column rename, drop, type change, table rename)
   - **Semantic** — changes meaning of existing data (metric definition, filter logic, join logic)
   - **Infrastructural** — changes location, format, or frequency (table moved, Parquet→Delta, hourly→daily)

2. Determine the **Severity**:
   - **Breaking** — existing consumers will fail or return wrong results
   - **Additive** — only adds new things; no consumer impact
   - **Safe** — no externally observable effect (internal refactor)

3. Determine the **Surface**:
   - column / table / model / pipeline / schema / source

4. State the reasoning for each axis in one sentence each. Make the reasoning concrete — cite the specific aspect of the change that determines the classification.

## Output

Write the artifact to `docs/data-changes/<YYYY-MM-DD>-<slug>/01-change-classification.md`.

Use this structure:

```markdown
# Stage 1 — Change Classification

## Change summary
<one paragraph: what is changing, from what to what>

## Classification

| Axis | Value |
|---|---|
| Kind | <Structural | Semantic | Infrastructural> |
| Severity | <Breaking | Additive | Safe> |
| Surface | <column | table | model | pipeline | schema> |

## Reasoning

- **<Kind>** — <why this kind>
- **<Severity>** — <why this severity, citing what will fail>
- **<Surface>** — <scope of the change>
```

## When in doubt

- If the change description is ambiguous, ask the user ONE clarifying question. Do not guess.
- If you cannot determine severity confidently, default to **Breaking** and explain. Over-flagging is cheap; under-flagging is catastrophic.
```

- [ ] **Step 2: Commit**

```bash
git add skill/references/stage-1-classify.md
git commit -m "Add Stage 1 (classify) reference"
```

### Task 6: Manually test Stage 1 against fixture 01

- [ ] **Step 1: Run the skill in a sandbox**

In a Claude Code session with the skill installed (drop `skill/` into `~/.claude/skills/blast-radius/`), open the fixture folder and invoke:

> "Use the blast-radius skill. The proposed change is in `change.md`. Run only Stage 1."

- [ ] **Step 2: Save the produced artifact**

Save the produced output to `tests/runs/01-dbt-rename/01-change-classification.md`.

- [ ] **Step 3: Diff against golden**

```bash
diff tests/runs/01-dbt-rename/01-change-classification.md tests/fixtures/01-dbt-rename/golden/01-change-classification.md
```

Expected: the classification table fields match exactly (Structural / Breaking / Column). Prose may vary.

- [ ] **Step 4: If diff reveals structural gaps, refine the reference doc**

Iterate on `skill/references/stage-1-classify.md` until the structural fields match. Re-run.

- [ ] **Step 5: Commit any refinements**

```bash
git add skill/references/stage-1-classify.md tests/runs/
git commit -m "Validate Stage 1 against fixture 01; refine reference"
```

### Task 7: Write Stage 2 reference doc

**Files:**
- Create: `skill/references/stage-2-trace.md`

- [ ] **Step 1: Write the Stage 2 reference**

`skill/references/stage-2-trace.md`:
```markdown
# Stage 2 — Trace consumers

## Input
- The changed object (table or column name) from Stage 1
- The repo root (default: cwd)

## What to do

### Phase A — Fast grep

Run grep for the literal name across these globs:
- `*.sql`
- `*.py`
- `*.yml`, `*.yaml`
- `*.ipynb`

Excludes: `.git`, `node_modules`, `.venv`, `dist`, `build`, `__pycache__`.

Announce the search before running:
> Searching for 'customer_age' in *.sql, *.py, *.yml, *.ipynb across repo root...

### Phase B — Classify each hit

For each file with a hit, read the file and identify the stack:

| File pattern | Stack |
|---|---|
| `*.sql` with `{{ ref(...) }}` or `{{ source(...) }}` | dbt model |
| `*.sql` without dbt jinja | raw SQL |
| `*.py` with `pd.read_sql`, `spark.read.table`, or SQL strings | Python |
| `schema.yml`, `*.yml` with `version: 2` | dbt schema doc |
| `*.ipynb` | notebook |
| Airflow DAG file (has `from airflow`) | orchestration |

### Phase C — Extract usage context

For each hit, classify how the column/table is used:
- **SELECT** — listed in a select clause (will-break on rename)
- **WHERE / FILTER** — used in predicate (will-break)
- **JOIN** — used in join condition (will-break)
- **ASSIGNMENT** — defining the column (this IS the source)
- **DOCUMENTATION** — schema.yml entry (will go stale)
- **COMMENT ONLY** — just in a code comment (safe)

## Output

Write artifact to `docs/data-changes/<slug>/02-consumer-inventory.md`. Stream entries as you find them — do not buffer.

Structure:

```markdown
# Stage 2 — Consumer Inventory

## Search scope
- Repo root: <path>
- Patterns searched: <name> in <globs>
- Files scanned: <count> by file type

## Consumers found

### <filename> (<stack>)
- **Path:** <path>:<line>
- **Stack:** <stack>
- **Usage:** <SELECT|WHERE|JOIN|ASSIGNMENT|DOCUMENTATION>
- **Snippet:** `<one-line snippet>`

(... repeat for each consumer)

## Summary
- Total consumers: <count> files, <count> references
- Stacks affected: <list>
- Notes: <any caveats — parse failures, cross-repo flags>
```

## Failure modes

- Zero consumers found → state explicitly at the top of the inventory: "No consumers found in scope. This does NOT imply safety — verify scope is correct and consider broadening search."
- Parse failure on a file → list it under "Parse failures — manual review required" rather than silently skipping.
```

- [ ] **Step 2: Commit**

```bash
git add skill/references/stage-2-trace.md
git commit -m "Add Stage 2 (trace) reference with search and classification logic"
```

### Task 8: Manually test Stage 2 against fixture 01

- [ ] **Step 1: Invoke Stage 2 in a Claude Code session**

In the fixture sandbox, ask:
> "Continue with Stage 2 — trace consumers of `customer_age` in `stg_customers`."

- [ ] **Step 2: Save produced output**

Save to `tests/runs/01-dbt-rename/02-consumer-inventory.md`.

- [ ] **Step 3: Diff against golden**

```bash
diff tests/runs/01-dbt-rename/02-consumer-inventory.md tests/fixtures/01-dbt-rename/golden/02-consumer-inventory.md
```

Expected: every consumer in the golden appears in the produced output. Path + line + stack should match. Prose may vary.

- [ ] **Step 4: Refine if needed and commit**

```bash
git add skill/references/stage-2-trace.md tests/runs/
git commit -m "Validate Stage 2 against fixture 01"
```

### Task 9: Write Stage 3 reference doc

**Files:**
- Create: `skill/references/stage-3-risk.md`

- [ ] **Step 1: Write the Stage 3 reference**

`skill/references/stage-3-risk.md`:
```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skill/references/stage-3-risk.md
git commit -m "Add Stage 3 (risk) reference with scoring rubric"
```

### Task 10: Manually test Stage 3 against fixture 01

- [ ] **Step 1: Invoke Stage 3 in a Claude Code session**

> "Continue with Stage 3 — assess risk for the consumers found in Stage 2."

- [ ] **Step 2: Save output**

Save to `tests/runs/01-dbt-rename/03-risk-assessment.md`.

- [ ] **Step 3: Diff against golden**

```bash
diff tests/runs/01-dbt-rename/03-risk-assessment.md tests/fixtures/01-dbt-rename/golden/03-risk-assessment.md
```

Expected: every consumer in the golden table appears in the produced table with matching Criticality and Severity. Owner field may be "Unknown" in both.

- [ ] **Step 4: Refine if needed, commit**

```bash
git add skill/references/stage-3-risk.md tests/runs/
git commit -m "Validate Stage 3 against fixture 01"
```

### Task 11: Write Stage 4 reference doc

**Files:**
- Create: `skill/references/stage-4-migrate.md`

- [ ] **Step 1: Write the Stage 4 reference**

`skill/references/stage-4-migrate.md`:
```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skill/references/stage-4-migrate.md
git commit -m "Add Stage 4 (migrate) reference with strategy selection rubric"
```

### Task 12: Manually test Stage 4 against fixture 01

- [ ] **Step 1: Invoke and save Stage 4**

> "Continue with Stage 4 — generate the migration plan."

Save output to `tests/runs/01-dbt-rename/04-migration-plan.md`.

- [ ] **Step 2: Diff against golden**

```bash
diff tests/runs/01-dbt-rename/04-migration-plan.md tests/fixtures/01-dbt-rename/golden/04-migration-plan.md
```

Expected: the chosen strategy matches (deprecation window with dual columns) and the per-consumer step list covers all 3 files.

- [ ] **Step 3: Refine and commit**

```bash
git add skill/references/stage-4-migrate.md tests/runs/
git commit -m "Validate Stage 4 against fixture 01"
```

### Task 13: Write Stage 5 reference doc

**Files:**
- Create: `skill/references/stage-5-comms.md`

- [ ] **Step 1: Write the Stage 5 reference**

`skill/references/stage-5-comms.md`:
```markdown
# Stage 5 — Draft stakeholder communications

## Input
- The migration plan (Stage 4)
- The risk assessment (Stage 3) — for owner targeting

## What to do

Produce three communication artifacts: Slack draft, PR description template, changelog entry.

### Slack draft

Audience: the data engineering channel and any specific consumer owners identified in Stage 3.

Format: short, scannable. Lead with the change. Name affected models. State the rollout window. Link the migration plan.

If owners are Unknown, request that maintainers self-identify.

### PR description template

Sections:
1. **Summary** — what is changing in one sentence
2. **Blast radius** — count of consumers affected, broken down by stack
3. **Rollout** — strategy name + window
4. **References** — paths to the artifacts in `docs/data-changes/<slug>/`

### Changelog entry

For projects with a `CHANGELOG.md` or release notes. Categorize under Deprecated, Removed, or Changed. Include the deprecation removal date.

## Output

Write artifact to `docs/data-changes/<slug>/05-stakeholder-comms.md`.

Structure:

```markdown
# Stage 5 — Stakeholder Communications

## Slack draft (for #<channel>)

> <message body>

## PR description template

\`\`\`
## Summary
<one sentence>

## Blast radius
- <count> downstream <stack> consumers affected (<file list>)
- <any cross-stack notes>

## Rollout
<strategy> with <window>.

## References
- Migration plan: docs/data-changes/<slug>/04-migration-plan.md
- Risk assessment: docs/data-changes/<slug>/03-risk-assessment.md
\`\`\`

## Changelog entry

\`\`\`
### <Deprecated|Removed|Changed>
- <description with dates>
\`\`\`
```
```

- [ ] **Step 2: Commit**

```bash
git add skill/references/stage-5-comms.md
git commit -m "Add Stage 5 (comms) reference with three communication templates"
```

### Task 14: Manually test Stage 5 against fixture 01 and run full end-to-end

- [ ] **Step 1: Invoke and save Stage 5**

> "Continue with Stage 5 — draft stakeholder comms."

Save to `tests/runs/01-dbt-rename/05-stakeholder-comms.md`.

- [ ] **Step 2: Diff against golden**

```bash
diff tests/runs/01-dbt-rename/05-stakeholder-comms.md tests/fixtures/01-dbt-rename/golden/05-stakeholder-comms.md
```

Expected: three sections present (Slack, PR template, changelog). Counts in PR template match Stage 2 inventory.

- [ ] **Step 3: Run full pipeline end-to-end fresh**

In a clean Claude Code session, delete `tests/runs/01-dbt-rename/`, then invoke:

> "Use the blast-radius skill on the proposed change in `tests/fixtures/01-dbt-rename/change.md`. Run all five stages."

- [ ] **Step 4: Diff every produced artifact against its golden**

```bash
for n in 01-change-classification 02-consumer-inventory 03-risk-assessment 04-migration-plan 05-stakeholder-comms; do
  echo "=== $n ==="
  diff tests/runs/01-dbt-rename/$n.md tests/fixtures/01-dbt-rename/golden/$n.md || true
done
```

Expected: structural fields match. Prose may vary.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Validate full pipeline (Stages 1-5) against fixture 01 end-to-end"
```

---

## Phase C — Expand coverage with cross-stack fixtures

For each fixture below, follow the same loop:
1. Build the fixture (small, realistic)
2. Write the 5 golden artifacts
3. Run the skill end-to-end against the fixture
4. Diff vs goldens; refine references where structural fields diverge
5. Commit

### Task 15: Fixture 02 — Python + Airflow consumer

**Goal:** verify cross-stack detection (dbt + Python + Airflow YAML — covering three of the five v1 stacks in one fixture).

**Setup:**
- Reuse the dbt models from fixture 01
- Add `pipelines/extract_age_features.py` that does `spark.read.table('analytics.dim_customers')` and references the `customer_age` column
- Add `dags/customer_features_dag.yml` (Airflow YAML config) that references `customer_age` as a feature column

**Files to create:**
- `tests/fixtures/02-python-consumer/...` (model files + Python file + Airflow YAML)
- `tests/fixtures/02-python-consumer/golden/*.md` (5 artifacts; Stage 2 inventory must include BOTH the Python file and the Airflow YAML)
- `tests/fixtures/02-python-consumer/change.md`

Same loop: build → golden → run → diff → refine → commit.

### Task 16: Fixture 03 — Notebook consumer

**Goal:** verify notebook scanning.

**Setup:**
- A small dbt project + one `.ipynb` notebook with a SQL cell referencing the table

**Files:** as above, with notebook content captured in `notebooks/eda.ipynb`.

Same loop.

### Task 17: Fixture 04 — Grain change (semantic)

**Goal:** verify Stage 1 correctly classifies a **Semantic** change rather than Structural.

**Setup:**
- A dbt model where the change is "redefine `dim_customers` to be at household grain instead of customer grain"
- The column names don't change — only the grain (and therefore the meaning of every row)

Same loop. Most important check: Stage 1 classifies as **Semantic / Breaking**, not Structural.

### Task 18: Fixture 05 — Safe refactor

**Goal:** verify the skill correctly identifies a non-breaking change and does not generate false alarms.

**Setup:**
- A change that's internal to the model — e.g., a CTE renamed inside `dim_customers.sql` with no externally visible change.

**Expected:** Stage 1 classifies as **Safe**. Stage 2 either skips or reports "no breaking consumers since change is internal." Migration plan is a one-liner.

### Task 19: Fixture 06 — Ambiguous intent

**Goal:** verify Stage 1 asks a clarifying question instead of guessing.

**Setup:**
- `change.md` says only: "I want to change the customers table"

**Expected:** Stage 1 does NOT proceed; instead asks: "What specifically about `customers` are you changing — a column, the schema, the source, the grain, the semantics?"

The "golden" for this fixture is a `01-clarifying-question.md` showing the expected question form.

### Task 20: Fixture 07 — Empty repo

**Goal:** verify the skill handles "no consumers found" cleanly.

**Setup:**
- A repo with the target table defined but no downstream consumers

**Expected:** Stage 2 inventory states explicitly: "No consumers found. This does NOT imply safety." Stages 3-5 are degenerate but should still run.

---

## Phase D — Polish

### Task 21: Write README.md and INSTALL.md

**Files:**
- Modify: `README.md`
- Create: `INSTALL.md`

- [ ] **Step 1: Rewrite `README.md`**

Expand from the placeholder to cover: what it does, why it exists, install + first-use example, link to spec.

- [ ] **Step 2: Write `INSTALL.md`**

Cover:
- Drop `skill/` into `~/.claude/skills/blast-radius/` (or symlink)
- Invoke via "use the blast-radius skill" in a Claude Code session
- Where artifacts get written

- [ ] **Step 3: Commit**

```bash
git add README.md INSTALL.md
git commit -m "Add user-facing README and install docs"
```

### Task 22: Real-world validation against Jaffle Shop

- [ ] **Step 1: Clone a public Jaffle Shop dbt repo**

```bash
git clone https://github.com/dbt-labs/jaffle_shop.git /tmp/jaffle_shop
```

- [ ] **Step 2: Invoke the skill against a realistic change**

In a Claude Code session opened on `/tmp/jaffle_shop`:
> "Use the blast-radius skill. I want to rename `customer_lifetime_value` to `lifetime_value` in `customers`."

- [ ] **Step 3: Manually inspect the produced artifacts in `docs/data-changes/...`**

Verify:
- The consumer inventory lists every reference (grep manually to confirm)
- The classification is correct (Structural / Breaking)
- The migration plan is realistic
- The Slack/PR drafts are usable

- [ ] **Step 4: Document findings**

Write `tests/real-world-validation.md` summarizing what worked and what didn't.

- [ ] **Step 5: Commit findings**

```bash
git add tests/real-world-validation.md
git commit -m "Real-world validation against Jaffle Shop"
```

---

## Done criteria (v1 complete)

- All seven fixtures pass: skill produces artifacts whose structural fields match the goldens
- Real-world validation against a public dbt repo passes inspection
- README and INSTALL docs exist
- Repo has a GitHub remote and all commits pushed
- A user with zero setup can drop `skill/` into `~/.claude/skills/` and invoke it on their own repo

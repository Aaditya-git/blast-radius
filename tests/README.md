# Testing blast-radius

## What "testing" means for a Markdown skill

This skill has no unit tests. Testing means: invoke Claude Code with the skill loaded, run it against a fixture, and compare the produced artifacts to the golden files in `fixtures/<N>/golden/`.

The golden files are the "tests." The stage reference docs (`skill/references/stage-N-*.md`) are the "implementation." If produced artifacts diverge from goldens on structural fields (classification table, consumer paths, severity ratings), the reference doc needs refinement.

## Fixtures

| # | Fixture | What it tests |
|---|---|---|
| 01 | `01-dbt-rename` | Basic dbt lineage — column rename, two direct consumers, no transitive chain |
| 02 | `02-python-consumer` | Transitive cross-stack chain — dbt → Python → Airflow (depth 3) |
| 03 | `03-notebook-consumer` | Transitive notebook detection — dbt → notebook (depth 2) |
| 04 | `04-grain-change` | Semantic classification — grain change causes silent data corruption, not compile failure |
| 05 | `05-safe-refactor` | No false alarms — internal CTE rename has zero external consumers |
| 06 | `06-ambiguous-intent` | Skill asks clarifying question instead of guessing |
| 07 | `07-empty-repo` | Zero consumers — skill flags clearly, does not imply safety |

## Run a fixture

Follow the checklist in `run-manual.md`.

## Where produced artifacts go

Save each test run's output to `tests/runs/<fixture-name>/`. These are not committed — they are working files for the test session.

## What "passing" means

**Stage 1:** Kind / Severity / Surface match the golden classification table exactly.

**Stage 2 (impact tree):**
- Every consumer in the golden impact tree appears in the produced output
- Impact type matches (DIRECT vs TRANSITIVE depth N)
- Break classification matches (WILL-BREAK / SILENT-PROPAGATION / TRANSITIVE-RISK / WILL-GO-STALE)
- No consumer from the golden is missing (missing = false negative = failure)
- Transitive consumers are found at the correct depth

**Stage 3:** Criticality and Severity match for every consumer in the risk table.

**Stage 4:** Chosen strategy matches the golden (e.g., "deprecation window" vs "coordinated update").

**Stage 5:** All three sections present — Slack draft, PR description template, changelog entry.

Prose and formatting may vary. Structural fields must match.

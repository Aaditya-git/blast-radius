# Testing blast-radius

## What "testing" means for a Markdown skill

This skill has no unit tests. Testing means: invoke Claude Code with the skill loaded, run it against a fixture, and compare the produced artifacts to the golden files in `fixtures/<N>/golden/`.

The golden files are the "tests." The stage reference docs (`skill/references/stage-N-*.md`) are the "implementation." If produced artifacts diverge from goldens on structural fields (classification table, consumer paths, severity ratings), the reference doc needs refinement.

## Fixtures

| # | Fixture | What it tests |
|---|---|---|
| 01 | `01-dbt-rename` | Basic dbt ref tracing — column rename, two downstream models |
| 02 | `02-python-consumer` | Cross-stack detection — dbt + Python Spark + Airflow YAML |
| 03 | `03-notebook-consumer` | Notebook scanning — SQL strings in .ipynb |
| 04 | `04-grain-change` | Semantic classification — grain change, no schema diff |
| 05 | `05-safe-refactor` | No false alarms — internal CTE rename |
| 06 | `06-ambiguous-intent` | Skill asks clarifying question instead of guessing |
| 07 | `07-empty-repo` | Zero consumers — skill flags clearly, does not imply safety |

## Run a fixture

Follow the checklist in `run-manual.md`.

## Where produced artifacts go

Save each test run's output to `tests/runs/<fixture-name>/`. These are not committed — they are working files for the test session.

## What "passing" means

- Classification table fields match the golden (Kind / Severity / Surface)
- Consumer inventory contains every consumer in the golden (path + stack + usage)
- Risk table severity ratings match the golden
- Prose and formatting may vary

# blast-radius

A Claude Code superpowers-style skill that traces the full blast radius of breaking data changes across dbt, SQL, Python, notebooks, and orchestration code.

## Project structure

```
skill/                        # The skill itself (installed by end users)
  SKILL.md                    # Entry point: activation rules, workflow checklist
  references/                 # Stage-specific instruction files (read on demand)
  README.md                   # Install + usage for end users
tests/
  fixtures/                   # Miniature repos for manual testing
    01-dbt-rename/
    02-python-consumer/
    03-notebook-consumer/
    04-grain-change/
    05-safe-refactor/
    06-ambiguous-intent/
    07-empty-repo/
  golden/                     # Expected output artifacts per fixture
docs/superpowers/
  specs/                      # Design spec
  plans/                      # Implementation plans
```

## Conventions

- **Output location:** `docs/data-changes/<YYYY-MM-DD>-<slug>/` — visible, committed, shows up in PRs
- **Stage artifacts:** named `01-change-classification.md` through `05-stakeholder-comms.md`
- **No executable code in v1** — Claude does all the work with grep, Read, and Bash tools already available in a Claude Code session
- **Err toward over-reporting** — false positives are cheap, false negatives are catastrophic

## Commit messages

No "Co-Authored-By" trailers. Short imperative subject line.

## Implementation plan

`docs/superpowers/plans/2026-05-15-blast-radius.md` — 22 tasks across 4 phases. Use the `superpowers:executing-plans` or `superpowers:subagent-driven-development` skill to execute.

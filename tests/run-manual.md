# Manual test checklist

Follow this checklist to validate the skill against a fixture.

## Prerequisites

- [ ] `skill/` is installed: `~/.claude/skills/blast-radius/` exists and contains `SKILL.md` and `references/`
- [ ] You are in a Claude Code session opened on the fixture directory (e.g., `tests/fixtures/01-dbt-rename/`)

## Per-fixture checklist

### Setup

- [ ] Note the fixture number and name: ___________
- [ ] Read `change.md` to understand the proposed change
- [ ] Open `golden/` in a file viewer so you can compare as you go

### Stage 1 — Classify

- [ ] Invoke: `"Use the blast-radius skill. The proposed change is in change.md. Run only Stage 1."`
- [ ] Save the produced artifact to `tests/runs/<fixture>/01-change-classification.md`
- [ ] Diff against golden: `diff tests/runs/<fixture>/01-change-classification.md tests/fixtures/<fixture>/golden/01-change-classification.md`
- [ ] Verify: Kind / Severity / Surface match the golden
- [ ] **For fixture 06 only:** verify Claude asks a clarifying question instead of producing a classification

### Stage 2 — Trace consumers

- [ ] Invoke: `"Continue with Stage 2 — trace consumers."`
- [ ] Save to `tests/runs/<fixture>/02-consumer-inventory.md`
- [ ] Diff against golden
- [ ] Verify: every consumer in the golden appears in the produced output (path + stack + usage)
- [ ] Verify: no consumers from the golden are missing
- [ ] **For fixture 07 only:** verify the "No consumers found — this does NOT imply safety" warning is prominent

### Stage 3 — Risk assessment

- [ ] Invoke: `"Continue with Stage 3."`
- [ ] Save to `tests/runs/<fixture>/03-risk-assessment.md`
- [ ] Diff against golden
- [ ] Verify: Criticality and Severity match for every consumer

### Stage 4 — Migration plan

- [ ] Invoke: `"Continue with Stage 4."`
- [ ] Save to `tests/runs/<fixture>/04-migration-plan.md`
- [ ] Diff against golden
- [ ] Verify: chosen strategy matches the golden (e.g., "deprecation window" vs "coordinated update")
- [ ] Verify: per-consumer steps cover every will-break consumer

### Stage 5 — Stakeholder comms

- [ ] Invoke: `"Continue with Stage 5."`
- [ ] Save to `tests/runs/<fixture>/05-stakeholder-comms.md`
- [ ] Diff against golden
- [ ] Verify: Slack draft, PR description template, and changelog entry are all present
- [ ] Verify: consumer counts in PR template match Stage 2 inventory

### Full end-to-end run

After all stages pass individually:

- [ ] Delete `tests/runs/<fixture>/` and start fresh
- [ ] Invoke: `"Use the blast-radius skill on the proposed change in change.md. Run all five stages."`
- [ ] Run the diff loop:

```bash
FIXTURE=01-dbt-rename   # change per fixture
for n in 01-change-classification 02-consumer-inventory 03-risk-assessment 04-migration-plan 05-stakeholder-comms; do
  echo "=== $n ==="
  diff tests/runs/$FIXTURE/$n.md tests/fixtures/$FIXTURE/golden/$n.md || true
done
```

- [ ] Structural fields all match → fixture **PASSES**
- [ ] Any structural field mismatch → refine the relevant stage reference doc and rerun

## Refinement loop

If a stage produces output that diverges from the golden on structural fields:

1. Identify which field diverges (e.g., wrong Severity, missing consumer, wrong strategy)
2. Open `skill/references/stage-N-*.md` for that stage
3. Add or clarify the instruction that would prevent the divergence
4. Rerun that stage against the fixture
5. Repeat until the field matches

Commit refinements after each passing fixture.

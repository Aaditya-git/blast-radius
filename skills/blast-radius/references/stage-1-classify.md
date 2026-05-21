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

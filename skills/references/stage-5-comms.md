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

Structure (use \`\`\` for inner code blocks to avoid nesting issues):

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

# Stage 5 — Stakeholder Communications

## Slack draft (for #data-eng channel)

> Heads up — renaming `event_type` → `event_category` in `stg_events`.
>
> **No consumers found in this repo.** However, cross-repo consumers (BI tools, ML pipelines, external queries) may exist and were not checked.
>
> If you have any pipeline or dashboard reading from `stg_events.event_type`, please reply before this merges.

## PR description template

```
## Summary
Renames `event_type` → `event_category` in `stg_events`.

## Blast radius
- 0 consumers found in this repo
- Cross-repo consumers not verified — flag if you know of any

## Rollout
Hard cut (pending cross-repo verification).

## References
- Risk assessment: `docs/data-changes/<date>-rename-event-type/03-risk-assessment.md`
```

## Changelog entry

```
### Changed
- `stg_events.event_type` renamed to `event_category`.
```

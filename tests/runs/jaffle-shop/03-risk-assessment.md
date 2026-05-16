# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `customers.sql` | Unknown (no env tag) | Silent-propagation | @dbt-labs/dx |
| `customers.yml` (MetricFlow semantic model) | Unknown | Will-break (MetricFlow dimension resolution failure) | @dbt-labs/dx |
| `customers.yml` (column doc) | Documentation | Will-go-stale | @dbt-labs/dx |

## Notes
- `customers.sql` uses `select *` from `stg_customers` — the `customer_name` column passes through silently. No SQL error at compile or query time. But the output column name of the `customers` mart changes from `customer_name` to `full_name`, breaking any consumer of the mart that expects `customer_name` by name (BI tools, external queries, ML pipelines).
- `customers.yml` line 45 is a MetricFlow semantic model dimension: `- name: customer_name`. MetricFlow will fail to resolve this dimension after the rename — it expects to find a `customer_name` column in the `customers` model, which will no longer exist.
- `customers.yml` line 13 is documentation only — no runtime failure, but the column description will be factually wrong after the rename.
- **This is a textbook silent propagation case.** A naive `grep -r customer_name models/` finds only 2 hits in `customers.yml` and misses `customers.sql` entirely. The graph traversal reveals a third impact that grep cannot see.
- Cross-repo impact is unverified: any BI dashboard, ML feature pipeline, or external SQL query selecting `customer_name` from the `customers` mart will silently break after the rename.

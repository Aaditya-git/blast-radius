# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `customers.sql` (mart output schema change) | Production (`models/marts/`) | Silent-propagation | @dbt-labs/dx (last author: Benoit Perigaud) |
| `customers.yml` line 45 (MetricFlow dimension) | Production | Will-break (MetricFlow query failure) | @dbt-labs/dx (last author: Benoit Perigaud) |
| `customers.yml` line 13 (column doc) | Documentation | Will-go-stale | @dbt-labs/dx |

## Notes
- `customers.sql` is in `models/marts/` — treated as production. No compile error will fire. The output of the `customers` mart silently changes: `customer_name` becomes `full_name` in the emitted table. Any BI dashboard, ML feature store, or external SQL query that selects `customers.customer_name` will break after deployment — with no warning at dbt compile time.
- `customers.yml` line 45 is a MetricFlow semantic model dimension definition. MetricFlow resolves dimensions by matching their `name:` against actual columns in the underlying model. After the rename, `customer_name` will not exist in `customers` — MetricFlow queries using the `customer_name` dimension will fail at query time.
- `customers.yml` line 13 is a dbt column description (`description: Customers' full name.`). No runtime failure — the description simply becomes factually wrong (wrong column name).
- Cross-repo risk is unverified and real: Jaffle Shop is a public demo repo; any system querying the `customers` table expecting `customer_name` is outside this search scope.

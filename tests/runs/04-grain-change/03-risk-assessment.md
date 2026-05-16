# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `fct_orders.sql` | Unknown (no env hints) | Will-break (silent data corruption) | Unknown (no CODEOWNERS) |
| `schema.yml` | Documentation | Will-go-stale | Unknown |

## Notes
- `fct_orders` joins `dim_customers` on `customer_id` — after the grain change, this join will produce a row per household member rather than per customer, silently multiplying order counts and aggregations
- No compile-time error will surface for this change; the failure mode is silent data corruption — rows look valid, numbers are wrong
- schema.yml grain description ("One row per customer. Grain: customer_id.") and customer_id description ("Primary key — unique per customer") will both be factually incorrect after the change

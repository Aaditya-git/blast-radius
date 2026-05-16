# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `fct_orders.sql` | Unknown (no env hints) | Will-break (silent data corruption) | Unknown (no CODEOWNERS) |
| `schema.yml` | Documentation | Will-go-stale | Unknown |

## Notes
- `fct_orders` joins `dim_customers` on `customer_id` — after the grain change, this join will produce a row per household member rather than per customer, silently multiplying order counts
- No compile-time error will surface for this change; the failure mode is silent data corruption
- schema.yml grain description will be factually wrong after the change

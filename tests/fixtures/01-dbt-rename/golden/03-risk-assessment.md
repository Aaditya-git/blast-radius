# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `fct_orders.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `schema.yml` | Documentation | Will-go-stale | Unknown |

## Notes
- Both downstream models reference `customer_age` in SELECT clauses — these will fail at compile time after the rename
- `dim_customers` derives `age_bucket` from `customer_age` — losing the source column also breaks the derived column
- `schema.yml` references will silently go stale; no compile failure but documentation drift

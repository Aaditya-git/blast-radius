# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints in path) | Will-break | Unknown (no CODEOWNERS) |
| `fct_orders.sql` | Unknown (no env hints in path) | Will-break | Unknown (no CODEOWNERS) |
| `schema.yml` | Documentation | Will-go-stale | Unknown |

## Notes
- Both `dim_customers` and `fct_orders` reference `customer_age` in SELECT clauses — they will fail at dbt compile time after the rename
- `dim_customers` additionally uses `customer_age` in a CASE expression to derive `age_bucket` — the derived column also breaks
- `schema.yml` references will silently go stale; no compile failure but documentation drifts from reality
- No CODEOWNERS file found — all owners marked Unknown; consider adding CODEOWNERS before migration to route notifications correctly

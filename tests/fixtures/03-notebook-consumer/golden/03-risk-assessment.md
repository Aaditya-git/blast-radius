# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `eda.ipynb` | Dev (notebook) | Will-break (runtime) | Unknown (no CODEOWNERS) |

## Notes
- The dbt model will fail at compile time
- The notebook will fail at runtime when the SQL string is executed — no compile-time warning
- Notebook cells reference `customer_age` in SELECT, CASE, WHERE, and DataFrame column access — all four must be updated

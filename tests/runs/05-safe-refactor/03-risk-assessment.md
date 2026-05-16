# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` (internal CTE only) | N/A | Safe | Unknown |

## Notes
- Both references to `base` are within `dim_customers.sql` itself — the CTE definition and its single use in the final SELECT
- No external model, Python file, notebook, or config references the CTE name `base`
- This change is safe to deploy without any consumer coordination

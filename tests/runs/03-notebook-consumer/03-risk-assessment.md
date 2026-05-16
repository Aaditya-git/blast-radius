# Stage 3 — Risk Assessment

| Consumer | Criticality | Severity | Owner |
|---|---|---|---|
| `dim_customers.sql` | Unknown (no env hints) | Will-break | Unknown (no CODEOWNERS) |
| `eda.ipynb` | Dev (notebook) | Will-break (runtime) | Unknown (no CODEOWNERS) |

## Notes
- `dim_customers` will fail at dbt compile time — explicit `customer_age` reference in SELECT
- `eda.ipynb` will fail at runtime when the SQL cell is executed — `pd.read_sql` will return no `customer_age` column; the plot cell accessing `df['customer_age']` will also raise a `KeyError`
- Notebook runtime failures are particularly deferred — the failure only surfaces when someone runs the notebook, not at merge time; notebook may appear healthy until next use
- 4 references across 2 cells all need updating

# Stage 1 — Change Classification

## Change summary
Redefine `dim_customers` from customer grain (one row per `customer_id`) to household grain (one row per `household_id`). Column names are unchanged. The meaning of every row changes.

## Classification

| Axis | Value |
|---|---|
| Kind | Semantic |
| Severity | Breaking |
| Surface | Model |

## Reasoning

- **Semantic** — no column is added, removed, or renamed; the physical schema is identical. The change is to the meaning of each row: `customer_id` goes from a unique primary key to a non-unique attribute. Consumers that assumed uniqueness (COUNT DISTINCT, JOIN on customer_id, per-customer aggregations) will silently produce wrong results.
- **Breaking** — downstream consumers joining or aggregating on `dim_customers` will silently over- or under-count; this is a data correctness failure, not a compile failure
- **Surface: Model** — the grain change affects the entire model, not a single column

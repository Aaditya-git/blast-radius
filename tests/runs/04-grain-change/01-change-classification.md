# Stage 1 — Change Classification

## Change summary
Redefine `dim_customers` from customer grain (one row per `customer_id`) to household grain (one row per `household_id`). Column names remain identical. The meaning of every row changes — `customer_id` becomes a non-unique attribute rather than a primary key. No backward compatibility shim is provided.

## Classification

| Axis | Value |
|---|---|
| Kind | Semantic |
| Severity | Breaking |
| Surface | Model |

## Reasoning

- **Semantic** — no column is added, removed, or renamed; the physical schema is unchanged. The change is to the meaning of each row: `customer_id` transitions from a unique primary key to a non-unique attribute. Consumers that assumed uniqueness (JOIN on customer_id, COUNT DISTINCT, per-customer aggregations) will silently produce wrong results.
- **Breaking** — downstream consumers joining or aggregating on `dim_customers` will silently over- or under-count; this is a data correctness failure, not a compile failure. No compile-time warning will fire.
- **Surface: Model** — the grain change affects the entire model, not a single column

# Proposed change

Redefine `dim_customers` to be at **household grain** instead of customer grain.

Currently: one row per `customer_id` (unique customer).
After: one row per `household_id` (a household may contain multiple customers).

The column names remain the same. `customer_id` will become a non-unique field in `dim_customers`. Aggregations that assumed `customer_id` uniqueness will silently over- or under-count.

No column renames. No schema changes. Logic change only.

# Proposed change

Rename the CTE `base` to `customers_base` inside `dim_customers.sql`.

This is a purely internal rename — the CTE is not referenced outside this file. The output columns of `dim_customers` are unchanged.

-- Current grain: one row per customer_id
select
    customer_id,
    first_name,
    last_name,
    email,
    signup_date,
    lifetime_value
from {{ ref('stg_customers') }}

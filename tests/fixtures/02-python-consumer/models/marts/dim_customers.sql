select
    customer_id,
    first_name || ' ' || last_name as full_name,
    customer_age,
    signup_date
from {{ ref('stg_customers') }}

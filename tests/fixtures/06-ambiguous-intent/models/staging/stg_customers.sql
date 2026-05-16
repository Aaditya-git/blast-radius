select
    customer_id,
    first_name,
    last_name,
    email,
    age_years,
    signup_date,
    lifetime_value
from {{ source('raw', 'customers') }}

select
    customer_id,
    first_name,
    last_name,
    age_years,
    signup_date
from {{ source('raw', 'customers') }}

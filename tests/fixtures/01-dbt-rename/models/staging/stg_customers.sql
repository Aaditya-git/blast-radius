select
    customer_id,
    first_name,
    last_name,
    customer_age,
    signup_date
from {{ source('raw', 'customers') }}

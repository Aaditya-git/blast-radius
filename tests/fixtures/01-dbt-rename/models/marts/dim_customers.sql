select
    customer_id,
    first_name || ' ' || last_name as full_name,
    customer_age,
    case
        when customer_age < 25 then 'young'
        when customer_age < 60 then 'middle'
        else 'senior'
    end as age_bucket,
    signup_date
from {{ ref('stg_customers') }}

select
    o.order_id,
    o.customer_id,
    c.customer_age,
    o.order_total,
    o.order_date
from {{ source('raw', 'orders') }} o
join {{ ref('stg_customers') }} c using (customer_id)

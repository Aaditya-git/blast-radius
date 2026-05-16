select
    o.order_id,
    o.customer_id,
    c.lifetime_value,
    o.order_total,
    o.order_date
from {{ source('raw', 'orders') }} o
join {{ ref('dim_customers') }} c using (customer_id)

-- BEFORE: CTE named 'base'
with base as (
    select
        customer_id,
        first_name || ' ' || last_name as full_name,
        age_years,
        signup_date
    from {{ ref('stg_customers') }}
)
select * from base

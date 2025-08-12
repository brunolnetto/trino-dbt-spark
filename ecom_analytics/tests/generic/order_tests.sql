{% test order_dates_are_valid(model, column_name) %}

with validation as (
    select
        {{ column_name }} as date_field
    from {{ model }}
    where date_field > current_date
        or date_field < '2016-01-01'  -- Assuming this is a reasonable start date for the dataset
)

select *
from validation

{% endtest %}

{% test payment_matches_items(model) %}

with order_payments as (
    select 
        order_id,
        sum(payment_value) as total_payment
    from {{ ref('olist_order_payments') }}
    group by order_id
),

order_items as (
    select 
        order_id,
        sum(price) as total_items_price
    from {{ ref('olist_order_items') }}
    group by order_id
),

final as (
    select 
        op.order_id,
        op.total_payment,
        oi.total_items_price
    from order_payments op
    join order_items oi on op.order_id = oi.order_id
    where abs(op.total_payment - oi.total_items_price) > 1  -- Allow for small rounding differences
)

select *
from final

{% endtest %}

{% test reasonable_payment_value(model, column_name) %}

with validation as (
    select
        {{ column_name }} as payment_value
    from {{ model }}
    where {{ column_name }} > 10000  -- Flag unusually high payment values
       or {{ column_name }} < 0       -- Flag negative values
)

select *
from validation

{% endtest %}

{% test positive_value(model, column_name) %}

with validation as (
    select
        {{ column_name }} as value_field
    from {{ model }}
    where {{ column_name }} < 0
)

select *
from validation

{% endtest %}

{% test revenue_consistency_check(model) %}

-- Test to ensure that the sum of proportional payment values 
-- equals the total payment for each order
with order_totals as (
    select 
        order_id,
        SUM(proportional_payment_value) as calculated_total,
        MAX(order_total_payment) as actual_total
    from {{ model }}
    group by order_id
),

inconsistent_orders as (
    select 
        order_id,
        calculated_total,
        actual_total,
        ABS(calculated_total - actual_total) as difference
    from order_totals
    where ABS(calculated_total - actual_total) > 0.01  -- Allow for small rounding differences
)

select *
from inconsistent_orders

{% endtest %}

{% test sales_growth_validation(model) %}

-- Test to identify unrealistic growth rates that might indicate data quality issues
with growth_validation as (
    select
        monthly,
        category,
        month_over_month_growth_pct
    from {{ model }}
    where month_over_month_growth_pct > 500  -- Growth > 500% might indicate data issues
       or month_over_month_growth_pct < -90  -- Decline > 90% might indicate data issues
)

select *
from growth_validation

{% endtest %}

{% test valid_category_counts(model, column_name) %}

with category_stats as (
    select 
        {{ column_name }} as category,
        count(*) as category_count
    from {{ model }}
    group by {{ column_name }}
    having count(*) < 3  -- Flag categories with too few items
)

select *
from category_stats

{% endtest %}

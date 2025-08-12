{% test reasonable_payment_value(model, column_name) %}

with validation as (
    select
        {{ column_name }} as payment_value
    from {{ model }}
    where {{ column_name }} > 10000  -- Flag unusually high payment values
),

final as (
    select *
    from validation
)

select *
from final

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

{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key="order_id"
    )
}}

SELECT
    order_id
    , order_item_id
    , product_id
    , seller_id
    , shipping_limit_date
    , price
    , freight_value
from {{ source('landing_zone', 'olist_order_items_dataset') }}

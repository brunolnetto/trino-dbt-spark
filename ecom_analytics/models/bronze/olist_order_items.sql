{{
        config(
            materialized='incremental',
            unique_key='order_item_id',
            incremental_strategy='delete+insert',
            partition_by=['order_id'],
            clustered_by=['product_id'],
            buckets=16
        )
    }}

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM {{ source('landing_zone', 'olist_order_items_dataset') }}

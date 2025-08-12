{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='delete+insert',
        partition_by=['order_purchase_timestamp'],
        clustered_by=['customer_id'],
        buckets=16
    )
}}

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM {{ source('landing_zone', 'olist_orders_dataset') }}

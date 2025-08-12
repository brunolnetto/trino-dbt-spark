{{
	config(
		materialized='incremental',
		unique_key='order_id',
		incremental_strategy='merge',
		partition_by=['order_purchase_timestamp'],
		clustered_by=['customer_id', 'product_id'],
		buckets=16
	)
}}

SELECT
    ro.order_id,
    ro.customer_id,
    ro.order_purchase_timestamp,
    roi.product_id,
    rop.payment_value,
    ro.order_status
FROM {{ source("silver", "olist_orders") }} AS ro
INNER JOIN {{ source("silver", "olist_order_items") }} AS roi
    ON ro.order_id = roi.order_id
INNER JOIN {{ source("silver", "olist_order_payments") }} AS rop
    ON ro.order_id = rop.order_id

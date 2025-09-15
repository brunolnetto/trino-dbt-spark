{{
	config(
		materialized='incremental',
		unique_key=['order_id', 'order_item_id'],
		incremental_strategy='merge',
		partition_by=['order_purchase_timestamp'],
		clustered_by=['customer_id', 'product_id'],
		buckets=16
	)
}}

WITH order_payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        COUNT(*) AS payment_count,
        ARRAY_AGG(payment_type) AS payment_types
    FROM {{ ref('olist_order_payments') }}
    GROUP BY order_id
),

fact_sales AS (
    SELECT
        ro.order_id,
        roi.order_item_id,
        ro.customer_id,
        ro.order_purchase_timestamp,
        ro.order_approved_at,
        ro.order_delivered_customer_date,
        ro.order_estimated_delivery_date,
        roi.product_id,
        roi.seller_id,
        roi.shipping_limit_date,
        roi.price AS item_price,
        roi.freight_value,
        -- Calculate proportional payment value for this item
        opa.total_payment_value AS order_total_payment,
        opa.payment_count,
        opa.payment_types,
        ro.order_status,
        ROUND(
            (roi.price / order_items_total.total_order_items_value)
            * opa.total_payment_value,
            2
        ) AS proportional_payment_value,
        -- Business metrics
        CASE
            WHEN ro.order_status = 'delivered' THEN 'Completed'
            WHEN ro.order_status IN ('shipped', 'processing') THEN 'In Progress'
            WHEN ro.order_status = 'canceled' THEN 'Canceled'
            ELSE 'Other'
        END AS order_status_category,

        -- Date calculations
        DATEDIFF(
            day, ro.order_purchase_timestamp, ro.order_delivered_customer_date
        ) AS delivery_days,
        DATEDIFF(
            day, ro.order_purchase_timestamp, ro.order_estimated_delivery_date
        ) AS estimated_delivery_days

    FROM {{ ref('olist_orders') }} AS ro
    INNER JOIN {{ ref('olist_order_items') }} AS roi
        ON ro.order_id = roi.order_id
    LEFT JOIN order_payments_agg AS opa
        ON ro.order_id = opa.order_id
    LEFT JOIN (
        -- Calculate total items value per order for proportional allocation
        SELECT
            order_id,
            SUM(price) AS total_order_items_value
        FROM {{ ref('olist_order_items') }}
        GROUP BY order_id
    ) AS order_items_total
        ON ro.order_id = order_items_total.order_id

    -- Only include orders with valid data
    WHERE
        ro.order_purchase_timestamp IS NOT NULL
        AND roi.price >= 0
        AND roi.freight_value >= 0
)

SELECT * FROM fact_sales

{% if is_incremental() %}
    WHERE order_purchase_timestamp >= (
        SELECT COALESCE(MAX(order_purchase_timestamp), '1900-01-01')
        FROM {{ this }}
    )
{% endif %}

{{
    config(
        materialized='incremental',
        unique_key=['order_id', 'payment_sequential'],
        incremental_strategy='delete+insert'
    )
}}

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM {{ source('landing_zone', 'olist_order_payments_dataset') }}

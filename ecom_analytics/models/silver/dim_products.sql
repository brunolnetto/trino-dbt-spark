{{
    config(
        materialized='incremental',
        unique_key='product_id',
        incremental_strategy='merge',
        clustered_by=['product_category_name_english'],
        buckets=8
    )
}}

SELECT
    rp.product_id,
    rp.product_category_name,
    rp.product_name_lenght,
    rp.product_description_lenght,
    rp.product_photos_qty,
    rp.product_weight_g,
    rp.product_length_cm,
    rp.product_height_cm,
    rp.product_width_cm,
    pcnt.product_category_name_english
FROM {{ ref('olist_products') }} AS rp
LEFT JOIN {{ source('landing_zone', 'product_category_name_translation') }} AS pcnt
    ON rp.product_category_name = pcnt.product_category_name

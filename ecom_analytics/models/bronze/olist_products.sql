{{
    config(
        materialized='incremental',
        unique_key='product_id',
        incremental_strategy='delete+insert',
        clustered_by=['product_category_name'],
        buckets=8
    )
}}

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ source('landing_zone', 'olist_products_dataset') }}

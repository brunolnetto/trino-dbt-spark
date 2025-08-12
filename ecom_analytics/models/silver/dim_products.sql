SELECT
    rp.product_id,
    pcnt.product_category_name_english
FROM {{ source('bronze', 'olist_products') }} AS rp
INNER JOIN {{ source('bronze', 'product_category_name_translation') }} AS pcnt
    ON rp.product_category_name = pcnt.product_category_name

SELECT
	rp.product_id
	, pcnt.product_category_name_english
FROM {{ source('bronze', 'olist_products') }} rp
JOIN {{ source('bronze', 'product_category_name_translation') }} pcnt
ON rp.product_category_name = pcnt.product_category_name
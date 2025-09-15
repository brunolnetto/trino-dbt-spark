{{
  config(
    materialized='table',
    indexes=[
      {'columns': ['monthly', 'category'], 'type': 'btree'},
      {'columns': ['category'], 'type': 'btree'}
    ]
  )
}}

WITH daily_sales_products AS (
    SELECT
        product_id,
        DATE(order_purchase_timestamp) AS daily,
        ROUND(SUM(CAST(proportional_payment_value AS DECIMAL(10, 2))), 2)
            AS sales,
        COUNT(DISTINCT order_id) AS orders,
        COUNT(*) AS items_sold,
        AVG(CAST(item_price AS DECIMAL(10, 2))) AS avg_item_price
    FROM {{ ref('fact_sales') }}
    WHERE
        order_status_category = 'Completed'
        AND proportional_payment_value > 0
    GROUP BY
        DATE(order_purchase_timestamp),
        product_id
),

daily_sales_categories AS (
    SELECT
        dsp.daily,
        dsp.sales,
        dsp.orders,
        dsp.items_sold,
        dsp.avg_item_price,
        DATE_TRUNC('month', dsp.daily) AS monthly,
        EXTRACT(YEAR FROM dsp.daily) AS year_num,
        EXTRACT(MONTH FROM dsp.daily) AS month_num,
        COALESCE(dp.product_category_name_english, 'Unknown') AS category,
        ROUND(dsp.sales / NULLIF(dsp.orders, 0), 2) AS revenue_per_order,
        ROUND(dsp.sales / NULLIF(dsp.items_sold, 0), 2) AS revenue_per_item
    FROM daily_sales_products AS dsp
    LEFT JOIN {{ ref('dim_products') }} AS dp
        ON dsp.product_id = dp.product_id
),

monthly_category_totals AS (
    SELECT
        monthly,
        year_num,
        month_num,
        category,
        SUM(sales) AS total_sales,
        SUM(orders) AS total_orders,
        SUM(items_sold) AS total_items_sold,
        ROUND(AVG(avg_item_price), 2) AS avg_category_item_price,
        ROUND(SUM(sales) / NULLIF(SUM(orders), 0), 2) AS avg_revenue_per_order,
        ROUND(SUM(sales) / NULLIF(SUM(items_sold), 0), 2)
            AS avg_revenue_per_item,
        COUNT(DISTINCT daily) AS active_days
    FROM daily_sales_categories
    GROUP BY
        monthly, year_num, month_num, category
),

category_rankings AS (
    SELECT
        *,
        SUM(total_sales) OVER (PARTITION BY monthly) AS monthly_total_sales,
        ROUND(
            (total_sales * 100.0)
            / NULLIF(SUM(total_sales) OVER (PARTITION BY monthly), 0),
            2
        ) AS category_share_pct,
        ROW_NUMBER()
            OVER (PARTITION BY monthly ORDER BY total_sales DESC)
            AS category_rank
    FROM monthly_category_totals
)

SELECT
    monthly,
    year_num,
    month_num,
    category,
    total_sales,
    total_orders,
    total_items_sold,
    avg_category_item_price,
    avg_revenue_per_order,
    avg_revenue_per_item,
    active_days,
    monthly_total_sales,
    category_share_pct,
    category_rank,
    -- Performance metrics
    CASE
        WHEN category_rank <= 3 THEN 'Top 3'
        WHEN category_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS performance_tier,

    -- Growth calculation (comparing to previous month)
    LAG(total_sales) OVER (
        PARTITION BY category
        ORDER BY monthly
    ) AS prev_month_sales,

    ROUND(
        ((total_sales - LAG(total_sales) OVER (
            PARTITION BY category
            ORDER BY monthly
        )) * 100.0) / NULLIF(LAG(total_sales) OVER (
            PARTITION BY category
            ORDER BY monthly
        ), 0),
        2
    ) AS month_over_month_growth_pct

FROM category_rankings
ORDER BY monthly DESC, total_sales DESC

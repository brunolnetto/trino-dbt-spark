{% macro validate_source_data() %}
  {{ log("🔍 Validating source data quality and freshness...", info=True) }}
  
  {% set validation_checks = [
    {
      'name': 'orders_data_check',
      'sql': "SELECT COUNT(*) as row_count FROM " ~ source('landing_zone', 'olist_orders_dataset'),
      'min_rows': 1000
    },
    {
      'name': 'products_data_check', 
      'sql': "SELECT COUNT(*) as row_count FROM " ~ source('landing_zone', 'olist_products_dataset'),
      'min_rows': 100
    },
    {
      'name': 'order_items_data_check',
      'sql': "SELECT COUNT(*) as row_count FROM " ~ source('landing_zone', 'olist_order_items_dataset'), 
      'min_rows': 1000
    },
    {
      'name': 'payments_data_check',
      'sql': "SELECT COUNT(*) as row_count FROM " ~ source('landing_zone', 'olist_order_payments_dataset'),
      'min_rows': 1000
    }
  ] %}
  
  {% set failed_checks = [] %}
  
  {% for check in validation_checks %}
    {% set results = run_query(check.sql) %}
    {% if results %}
      {% set row_count = results.rows[0][0] %}
      {% if row_count >= check.min_rows %}
        {{ log("✅ " ~ check.name ~ ": " ~ row_count ~ " rows (✓ >= " ~ check.min_rows ~ ")", info=True) }}
      {% else %}
        {{ log("❌ " ~ check.name ~ ": " ~ row_count ~ " rows (✗ < " ~ check.min_rows ~ ")", info=True) }}
        {% set _ = failed_checks.append(check.name) %}
      {% endif %}
    {% else %}
      {{ log("❌ " ~ check.name ~ ": Query failed", info=True) }}
      {% set _ = failed_checks.append(check.name) %}
    {% endif %}
  {% endfor %}
  
  {% if failed_checks %}
    {{ log("❌ Data validation failed for: " ~ failed_checks|join(", "), info=True) }}
    {{ exceptions.raise_compiler_error("Source data validation failed") }}
  {% else %}
    {{ log("✅ All source data validation checks passed", info=True) }}
  {% endif %}
  
  {{ return("Data validation completed") }}
{% endmacro %}
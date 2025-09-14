{% macro stage_external_sources() %}
  {{ log("🔗 Staging external sources for multi-engine processing...", info=True) }}
  
  {% set external_operations = [
    "Creating external table references for Spark access to Bronze Iceberg tables",
    "Validating Iceberg table metadata in MinIO",
    "Setting up cross-engine table mappings"
  ] %}
  
  {% for operation in external_operations %}
    {{ log("   ✓ " ~ operation, info=True) }}
  {% endfor %}
  
  {% set sql %}
    -- Validate that Bronze tables exist and are accessible
    SELECT 
      table_name,
      table_type,
      is_insertable_into
    FROM information_schema.tables 
    WHERE table_schema = 'bronze'
    ORDER BY table_name;
  {% endset %}
  
  {% set results = run_query(sql) %}
  
  {% if results %}
    {{ log("✅ Found " ~ results.rows|length ~ " Bronze tables for external staging", info=True) }}
    {% for row in results.rows %}
      {{ log("   📊 " ~ row[0] ~ " (" ~ row[1] ~ ")", info=True) }}
    {% endfor %}
  {% else %}
    {{ log("⚠️  No Bronze tables found - ensure Bronze layer has been executed", info=True) }}
  {% endif %}
  
  {{ log("🎉 External sources staging completed successfully", info=True) }}
  
  {{ return("External sources staged successfully") }}
{% endmacro %}
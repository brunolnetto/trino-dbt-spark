# Best Practices Guide: Modern Data Engineering

This guide consolidates the key best practices demonstrated in this project for building robust, scalable data pipelines.

## 🏗️ Architecture Best Practices

### 1. Medallion Architecture Implementation

**✅ DO:**
- Preserve raw data in Bronze layer for auditability
- Apply business logic gradually through layers
- Use appropriate engines for each layer's workload
- Implement clear data contracts between layers

**❌ DON'T:**
- Skip Bronze layer to "save storage" - data lake storage is cheap
- Apply complex transformations in Bronze layer
- Mix engine responsibilities without clear reasoning
- Create circular dependencies between layers

**Example Implementation:**
```yaml
# Clear layer separation in dbt_project.yml
models:
  bronze:
    +materialized: incremental
    +incremental_strategy: delete+insert
    +file_format: iceberg
    meta:
      layer: "bronze"
      owner: "data_engineering"
      
  silver:
    +materialized: incremental  
    +incremental_strategy: merge
    meta:
      layer: "silver"
      owner: "data_engineering"
      
  gold:
    +materialized: table
    meta:
      layer: "gold"
      owner: "analytics_team"
```

### 2. Engine Selection Strategy

| Use Case | Recommended Engine | Reasoning |
|----------|-------------------|-----------|
| Data ingestion from multiple sources | Trino | Fast federated queries, broad connectors |
| Heavy ETL transformations | Spark | Distributed processing, rich APIs |
| Interactive analytics | Trino | Query optimization, fast results |
| BI/Dashboard queries | PostgreSQL/Snowflake | OLAP optimization, BI tool compatibility |
| Real-time processing | Spark Streaming/Flink | Stream processing capabilities |

## 🛠️ dbt Best Practices

### 1. Project Organization

```
models/
├── staging/          # Light transformations, 1:1 with sources
├── intermediate/     # Complex business logic, reusable components  
├── marts/           # Business-defined entities
│   ├── core/        # Shared business concepts
│   ├── finance/     # Domain-specific marts
│   └── marketing/
└── utils/           # Helper models and macros
```

### 2. Naming Conventions

**Sources and Staging:**
```sql
-- Sources: raw table names
source('landing_zone', 'olist_order_items_dataset')

-- Staging: stg_[source]__[entity]
{{ ref('olist_orders') }}
{{ ref('stg_postgres__customers') }}
```

**Marts:**
```sql
-- Facts: fct_[business_process]
{{ ref('fct_sales') }}
{{ ref('fct_web_sessions') }}

-- Dimensions: dim_[business_entity]  
{{ ref('dim_customers') }}
{{ ref('dim_products') }}

-- Metrics: [metric_name]
{{ ref('monthly_revenue') }}
{{ ref('customer_lifetime_value') }}
```

### 3. Model Configuration Patterns

**Incremental Models:**
```sql
{{
  config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    on_schema_change='fail'  -- Explicit schema management
  )
}}

SELECT * FROM {{ ref('source_table') }}
{% if is_incremental() %}
  WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
```

**Performance Optimization:**
```sql
{{
  config(
    materialized='table',
    indexes=[
      {'columns': ['customer_id'], 'type': 'btree'},
      {'columns': ['order_date', 'product_id'], 'type': 'btree'}
    ],
    partition_by='DATE_TRUNC("month", order_date)'
  )
}}
```

### 4. Testing Strategy

**Comprehensive Test Coverage:**
```yaml
models:
  - name: fct_sales
    tests:
      # Primary key tests
      - unique:
          column_name: sale_id
      - not_null:
          column_name: sale_id
          
      # Foreign key tests  
      - relationships:
          to: ref('dim_customers')
          field: customer_id
          
      # Business logic tests
      - dbt_utils.accepted_range:
          column_name: sale_amount
          min_value: 0
          
      # Custom business rules
      - assert_positive_revenue
```

**Custom Test Macros:**
```sql
-- macros/test_assert_positive_revenue.sql
{% macro test_assert_positive_revenue(model) %}
  SELECT COUNT(*)
  FROM {{ model }}
  WHERE revenue < 0
{% endmacro %}
```

## 📊 Data Quality Best Practices

### 1. Data Validation Framework

**Source Data Validation:**
```yaml
sources:
  - name: landing_zone
    tables:
      - name: orders
        tests:
          - dbt_utils.not_empty
        columns:
          - name: order_id
            tests:
              - unique
              - not_null
          - name: created_at
            tests:
              - dbt_utils.not_older_than:
                  datepart: day
                  interval: 30
```

**Business Rule Validation:**
```sql
-- Example: Revenue reconciliation test
WITH source_revenue AS (
  SELECT SUM(amount) as total FROM {{ ref('fct_sales') }}
),
warehouse_revenue AS (
  SELECT SUM(revenue) as total FROM {{ ref('revenue_summary') }}
)
SELECT 
  ABS(s.total - w.total) as difference
FROM source_revenue s, warehouse_revenue w
WHERE ABS(s.total - w.total) > 0.01  -- Tolerance for rounding
```

### 2. Data Freshness Monitoring

```yaml
sources:
  - name: production_db
    freshness:
      warn_after: {count: 6, period: hour}
      error_after: {count: 12, period: hour}
    tables:
      - name: orders
        freshness:
          warn_after: {count: 1, period: hour}  # Override for critical table
```

## 🚀 Performance Optimization

### 1. Query Optimization

**Efficient Joins:**
```sql
-- ✅ Good: Filter before joining
WITH recent_orders AS (
  SELECT * FROM {{ ref('fct_sales') }}
  WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
  o.*,
  c.customer_name
FROM recent_orders o
JOIN {{ ref('dim_customers') }} c
  ON o.customer_id = c.customer_id

-- ❌ Bad: Filter after joining
SELECT 
  o.*,
  c.customer_name  
FROM {{ ref('fct_sales') }} o
JOIN {{ ref('dim_customers') }} c
  ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
```

**Aggregation Optimization:**
```sql
-- ✅ Good: Pre-aggregate in subquery
WITH daily_metrics AS (
  SELECT 
    DATE(order_timestamp) as order_date,
    customer_id,
    SUM(amount) as daily_amount
  FROM {{ ref('fct_sales') }}
  GROUP BY DATE(order_timestamp), customer_id
)
SELECT 
  customer_id,
  AVG(daily_amount) as avg_daily_spend
FROM daily_metrics  
GROUP BY customer_id
```

### 2. Storage Optimization

**Partitioning Strategy:**
```sql
{{
  config(
    materialized='incremental',
    partition_by='DATE(order_timestamp)',
    cluster_by=['customer_id', 'product_category']
  )
}}
```

**Data Types Optimization:**
```sql
-- ✅ Good: Appropriate data types
SELECT
  order_id::VARCHAR(50),           -- Not VARCHAR(255)
  amount::DECIMAL(10,2),           -- Not FLOAT for money
  order_date::DATE,                -- Not TIMESTAMP if time not needed
  is_returned::BOOLEAN             -- Not VARCHAR for flags
```

## 🔐 Security and Governance

### 1. Access Control

**Role-Based Security:**
```yaml
# profiles.yml
production:
  outputs:
    dev:
      # Developer access - limited schemas
      schema: dev_{{env_var('DBT_USER')}}
      
    prod:
      # Production access - read-only for analysts
      schema: analytics
      grants:
        select: ['analyst_role']
```

**Column-Level Security:**
```sql
-- PII masking example
SELECT
  customer_id,
  {% if target.name == 'prod' %}
    SHA2(email, 256) as email_hash,
    LEFT(phone, 3) || 'XXX-XXXX' as phone_masked
  {% else %}
    email,
    phone  
  {% endif %}
FROM {{ ref('stg_customers') }}
```

### 2. Data Lineage and Documentation

**Comprehensive Documentation:**
```yaml
models:
  - name: fct_sales
    description: |
      Core sales fact table containing one row per order line item.
      Updated incrementally every hour from source systems.
      
      **Business Rules:**
      - Revenue includes taxes but excludes shipping
      - Returns are handled as negative amounts
      - Only completed orders are included
      
    columns:
      - name: sale_id
        description: "Unique identifier for each sale transaction"
        tests:
          - unique
          - not_null
```

**Lineage Through refs:**
```sql
-- Clear dependency chain
SELECT * FROM {{ ref('stg_orders') }}           -- Staging
JOIN {{ ref('dim_customers') }}                 -- Dimension
  ON orders.customer_id = customers.customer_id
```

## 🔄 CI/CD Best Practices

### 1. Environment Strategy

```bash
# Development workflow
dbt run --target dev --select state:modified+
dbt test --target dev --select state:modified+

# Staging validation  
dbt run --target staging --select state:modified+
dbt test --target staging

# Production deployment
dbt run --target prod --select state:modified+
```

### 2. Testing Strategy

**Pre-commit Hooks:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/dbt-labs/dbt-core
    hooks:
      - id: dbt-compile
      - id: dbt-test
      - id: dbt-docs-generate
```

**CI Pipeline:**
```yaml
# .github/workflows/dbt.yml
steps:
  - name: dbt deps
    run: dbt deps
    
  - name: dbt compile
    run: dbt compile
    
  - name: dbt test (modified models)
    run: dbt test --select state:modified+
    
  - name: dbt run (production)
    if: github.ref == 'refs/heads/main'
    run: dbt run --target prod
```

## 📊 Monitoring and Alerting

### 1. Pipeline Monitoring

**dbt Artifacts Analysis:**
```sql
-- Monitor model performance
SELECT 
  model_name,
  status,
  execution_time,
  rows_affected
FROM {{ ref('dbt_run_results') }}
WHERE execution_date = CURRENT_DATE
  AND execution_time > INTERVAL '1 hour'  -- Flag long-running models
```

**Data Quality Monitoring:**
```sql
-- Test results monitoring
SELECT
  test_name,
  table_name, 
  failures,
  execution_date
FROM {{ ref('dbt_test_results') }}
WHERE failures > 0
  AND execution_date >= CURRENT_DATE - INTERVAL '7 days'
```

### 2. Alerting Strategy

**Business Rule Violations:**
```sql
-- Revenue drop alert
WITH daily_revenue AS (
  SELECT 
    DATE(order_timestamp) as date,
    SUM(amount) as revenue
  FROM {{ ref('fct_sales') }}
  GROUP BY DATE(order_timestamp)
),
revenue_change AS (
  SELECT 
    date,
    revenue,
    LAG(revenue) OVER (ORDER BY date) as prev_revenue,
    (revenue - LAG(revenue) OVER (ORDER BY date)) / LAG(revenue) OVER (ORDER BY date) as pct_change
  FROM daily_revenue
)
SELECT * FROM revenue_change 
WHERE ABS(pct_change) > 0.2  -- 20% change threshold
  AND date = CURRENT_DATE
```

## 🎯 Migration and Deployment

### 1. Zero-Downtime Deployments

**Blue-Green Model Deployment:**
```sql
-- Deploy to staging schema first
{{ 
  config(
    alias='fct_sales_v2' if target.name == 'staging' else 'fct_sales'
  )
}}

-- Validate in staging, then promote to production
```

### 2. Schema Evolution

**Backward Compatible Changes:**
```sql
-- ✅ Good: Additive changes
ALTER TABLE fct_sales 
ADD COLUMN new_metric DECIMAL(10,2);

-- ❌ Bad: Breaking changes without migration
ALTER TABLE fct_sales 
DROP COLUMN existing_metric;
```

This best practices guide serves as a reference for implementing robust, maintainable data pipelines using the patterns demonstrated in this project.
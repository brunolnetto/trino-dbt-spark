# Hands-On Tutorial: Building a Modern Data Pipeline

This tutorial provides practical exercises to help you learn by doing. Each exercise builds upon the previous one to create a complete understanding of the data pipeline.

## 🎯 Learning Objectives

By completing this tutorial, you will:
- Set up a modern data engineering environment
- Implement medallion architecture patterns
- Use multiple processing engines effectively
- Create and test dbt transformations
- Build end-to-end data pipelines

## 📋 Prerequisites

- Docker Desktop installed and running
- Basic SQL knowledge
- Command line familiarity
- Text editor or IDE

## 🏃‍♂️ Quick Start

### Exercise 1: Environment Setup

**Goal**: Get the complete data stack running locally

1. **Clone the repository**:
```bash
git clone https://github.com/brunolnetto/trino-dbt-spark
cd trino-dbt-spark
```

2. **Review the environment configuration**:
```bash
# Examine the environment file
cat .env

# Review the docker-compose setup
cat docker-compose.yml
```

3. **Start the infrastructure**:
```bash
# Build all containers
make build

# Start all services
make up

# Verify services are running
docker-compose ps
```

4. **Wait for health checks** (2-3 minutes):
```bash
# Monitor service health
watch docker-compose ps
```

**Expected Output**: All services should show "healthy" status.

### Exercise 2: Data Source Setup

**Goal**: Load sample e-commerce data into MySQL

1. **Connect to MySQL as root**:
```bash
make to_mysql_root
```

2. **Create the database and user**:
```sql
CREATE DATABASE brazillian_ecommerce;
USE brazillian_ecommerce;
GRANT ALL PRIVILEGES ON *.* TO admin;
SHOW GLOBAL VARIABLES LIKE 'LOCAL_INFILE';
SET GLOBAL LOCAL_INFILE=TRUE;
exit
```

3. **Connect as regular user**:
```bash
make to_mysql
```

4. **Create table schemas**:
```sql
-- Orders table
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- Order items table  
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

-- Products table
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Payments table
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

-- Category translation table
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
```

5. **Load sample data using seeds**:
```bash
# Exit MySQL and return to project directory
exit

# Load dbt seeds (CSV files)
cd ecom_analytics
make seed
```

**Verification**: Check that data was loaded:
```bash
make to_mysql
USE brazillian_ecommerce;
SELECT COUNT(*) FROM olist_orders_dataset;
SELECT COUNT(*) FROM olist_products_dataset;
```

### Exercise 3: Bronze Layer Implementation

**Goal**: Create raw data ingestion layer using Trino

1. **Examine Bronze layer configuration**:
```bash
# Review dbt project configuration
cat dbt_project.yml

# Check Bronze model sources
cat models/bronze/sources.yml
```

2. **Run Bronze layer models**:
```bash
# Run Bronze models with Trino profile
make run_bronze
```

3. **Inspect generated Bronze tables**:
```sql
-- Connect to Trino (via your SQL client or CLI)
SHOW SCHEMAS FROM warehouse;
SHOW TABLES FROM warehouse.bronze;
SELECT * FROM warehouse.bronze.olist_orders LIMIT 10;
```

4. **Examine the transformation logic**:
```bash
# Review a Bronze model
cat models/bronze/olist_orders.sql
```

**Learning Points**:
- Bronze layer preserves raw data structure
- Minimal transformations (data typing, basic validation)
- Delta Lake format provides ACID compliance
- Incremental materialization for efficiency

### Exercise 4: Silver Layer Transformations

**Goal**: Build cleaned and transformed data using Spark

1. **Review Silver layer models**:
```bash
# Check dimensional model structure
cat models/silver/dim_products.sql
cat models/silver/fact_sales.sql
```

2. **Run Silver layer transformations**:
```bash
# Run external sources staging
make run_external

# Run Silver models with Spark profile
make run_silver
```

3. **Inspect Silver layer results**:
```sql
-- Via Spark SQL or Trino
SELECT * FROM warehouse.silver.dim_products LIMIT 10;
SELECT * FROM warehouse.silver.fact_sales LIMIT 10;

-- Check data quality
SELECT 
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT product_id) as unique_products
FROM warehouse.silver.fact_sales;
```

**Learning Points**:
- Star schema design for analytics
- Business logic implementation
- Data quality improvements
- Merge incremental strategy for updates

### Exercise 5: Gold Layer Analytics

**Goal**: Create business-ready analytics using aggregations

1. **Review Gold layer models**:
```bash
cat models/gold/sales_values_by_category.sql
```

2. **Run Gold layer models**:
```bash
# Run Gold models with Gold profile (Trino + PostgreSQL)
make run_gold
```

3. **Query analytics results**:
```bash
# Connect to PostgreSQL
make to_psql

# Switch to analytics database
\c ecom_analytics;

# View gold layer tables
\dt

# Query business metrics
SELECT * FROM sales_values_by_category 
ORDER BY total_sales DESC 
LIMIT 10;
```

**Learning Points**:
- Business metric calculations
- Time-based aggregations
- Performance optimization for BI tools
- Cross-engine data movement

## 🔧 Advanced Exercises

### Exercise 6: Custom Transformation

**Goal**: Add a new business metric to the pipeline

1. **Create a new Gold layer model**:
```bash
# Create customer_analytics.sql
cat > models/gold/customer_analytics.sql << 'EOF'
WITH customer_metrics AS (
  SELECT 
    customer_id,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(CAST(payment_value AS FLOAT)), 2) as total_spent,
    ROUND(AVG(CAST(payment_value AS FLOAT)), 2) as avg_order_value,
    MIN(order_purchase_timestamp) as first_order_date,
    MAX(order_purchase_timestamp) as last_order_date
  FROM {{ source('silver', 'fact_sales') }}
  WHERE order_status = 'delivered'
  GROUP BY customer_id
)
SELECT 
  customer_id,
  total_orders,
  total_spent,
  avg_order_value,
  first_order_date,
  last_order_date,
  CASE 
    WHEN total_orders >= 5 THEN 'High Value'
    WHEN total_orders >= 3 THEN 'Medium Value'
    ELSE 'Low Value'
  END as customer_segment
FROM customer_metrics
EOF
```

2. **Add the model to Gold configuration**:
```yaml
# Update models/gold/sources.yml
version: 2

sources:
  - name: silver
    description: "Silver layer tables for Gold consumption"
    tables:
      - name: fact_sales
      - name: dim_products

models:
  - name: customer_analytics
    description: "Customer behavior analysis and segmentation"
    columns:
      - name: customer_id
        description: "Unique customer identifier"
        tests:
          - unique
          - not_null
```

3. **Run and test the new model**:
```bash
# Run the specific model
dbt run --models customer_analytics --profile gold

# Test the model
dbt test --models customer_analytics --profile gold
```

### Exercise 7: Data Quality Testing

**Goal**: Implement comprehensive data quality checks

1. **Add data quality tests**:
```yaml
# Update models/silver/schema.yml
models:
  - name: fact_sales
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - order_id
            - product_id
    columns:
      - name: payment_value
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 10000
      - name: order_purchase_timestamp
        tests:
          - not_null
```

2. **Run data quality tests**:
```bash
# Install dbt-utils if not already installed
dbt deps

# Run all tests
make test
```

### Exercise 8: Performance Optimization

**Goal**: Optimize query performance with partitioning

1. **Add partitioning to a Silver model**:
```sql
-- Update models/silver/fact_sales.sql
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['order_id', 'product_id'],
        partition_by='DATE(order_purchase_timestamp)'
    )
}}

-- Rest of the model remains the same
```

2. **Test performance improvements**:
```bash
# Run with partitioning
dbt run --models fact_sales --profile spark --full-refresh

# Query with partition pruning
# Use date filters in your analytics queries
```

## 📊 Monitoring and Troubleshooting

### Exercise 9: Pipeline Monitoring

1. **Generate documentation**:
```bash
make docs
# Documentation will be available at http://localhost:8080/
```

2. **Monitor service health**:
```bash
# Check Docker container status
docker-compose ps

# View service logs
docker-compose logs spark-master
docker-compose logs trino
```

3. **Debug failed models**:
```bash
# Run with debug output
dbt run --models <model_name> --profile <profile> --debug

# Check compiled SQL
cat target/compiled/ecom_analytics/models/<layer>/<model>.sql
```

### Common Issues and Solutions

**Issue**: Services not starting
```bash
# Solution: Check resource allocation
docker system prune
docker-compose down
docker-compose up -d
```

**Issue**: dbt connection errors
```bash
# Solution: Verify service health
docker-compose ps
# Wait for health checks to pass
```

**Issue**: Out of memory errors
```bash
# Solution: Adjust Spark configuration
# Edit docker/spark/spark-defaults.conf
spark.executor.memory=1g
spark.driver.memory=512m
```

## 🎓 Next Steps

After completing these exercises:

1. **Experiment with different data sources**
2. **Add more complex transformations**
3. **Implement real-time streaming (Kafka + Spark Streaming)**
4. **Add data governance features**
5. **Explore cloud deployment patterns**

## 📚 Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Trino Documentation](https://trino.io/docs/)
- [Delta Lake Documentation](https://docs.delta.io/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)

This hands-on tutorial provides a foundation for building modern data engineering skills through practical experience with industry-standard tools and patterns.
# 🚀 Quick Reference: Commands and Concepts

A handy reference card for working with this modern data engineering project.

## 📋 Essential Commands

### 🐳 Infrastructure Management
```bash
# Start everything
make build && make up

# Check service health
docker-compose ps

# View logs
docker-compose logs <service-name>

# Stop everything
make down

# Restart services
make restart
```

### 🔗 Database Connections
```bash
# MySQL (source data)
make to_mysql_root  # Root access
make to_mysql       # Regular user

# PostgreSQL (analytics)
make to_psql

# Connect to services
docker exec -it trino trino --server localhost:8080
docker exec -it spark-master /opt/bitnami/spark/bin/spark-sql
```

### 📊 dbt Pipeline Commands
```bash
cd ecom_analytics

# Complete pipeline
make run_all                    # Seed → Bronze → Silver → Gold

# Individual layers  
make seed                       # Load CSV seeds
make run_bronze                 # Raw data ingestion (Trino)
make run_external              # External table staging
make run_silver                # Data transformations (Spark)
make run_gold                  # Analytics aggregations (Trino+PostgreSQL)

# Development utilities
make docs                      # Generate documentation
make test                      # Run data quality tests
dbt compile --profile spark    # Check SQL compilation
```

### 🔧 Development Commands
```bash
# Run specific models
dbt run --models model_name --profile spark

# Run with dependencies
dbt run --models +model_name+ --profile spark

# Full refresh (rebuild from scratch)
dbt run --models model_name --profile spark --full-refresh

# Run tests for specific models
dbt test --models model_name --profile spark
```

## 🏗️ Architecture Quick Reference

### Data Flow
```
MySQL → Trino → Delta Lake (Bronze) → Spark → Delta Lake (Silver) → Trino → PostgreSQL (Gold) → Metabase
```

### Layer Responsibilities
| Layer | Engine | Purpose | Materialization |
|-------|--------|---------|----------------|
| **Bronze** | Trino | Raw data ingestion | Incremental (delete+insert) |
| **Silver** | Spark | Business logic & cleaning | Incremental (merge) |
| **Gold** | Trino | Analytics & aggregation | Table |

### dbt Profiles
```yaml
trino:   # Bronze layer - fast federated queries
spark:   # Silver layer - heavy transformations  
gold:    # Gold layer - analytics ready data
```

## 🔧 Configuration Quick Reference

### Key File Locations
```
├── .env                          # Environment variables
├── docker-compose.yml           # Service orchestration
├── ecom_analytics/
│   ├── dbt_project.yml          # dbt project config
│   ├── profiles.yml             # Connection profiles
│   └── models/                  # Data transformations
│       ├── bronze/              # Raw data models
│       ├── silver/              # Business logic models
│       └── gold/                # Analytics models
```

### Environment Variables (.env)
```bash
# Core services
MYSQL_HOST=de_mysql
POSTGRES_HOST=de_psql  
MINIO_URL=http://minio:9000

# Access credentials
MYSQL_PASSWORD=admin
POSTGRES_PASSWORD=admin123
MINIO_ROOT_PASSWORD=minio123
```

### Service URLs
- **Trino UI**: http://localhost:8080
- **Spark UI**: http://localhost:4040
- **MinIO Console**: http://localhost:9001
- **Metabase**: http://localhost:3000

## 📊 Data Models Quick Reference

### Bronze Layer (Trino)
```sql
-- Raw data replication
{{ source('landing_zone', 'table_name') }}

-- Minimal transformations
SELECT *, CURRENT_TIMESTAMP as loaded_at
FROM {{ source('mysql', 'orders') }}
```

### Silver Layer (Spark)  
```sql
-- Business logic and joins
SELECT 
    o.order_id,
    o.customer_id,
    oi.product_id,
    op.payment_value
FROM {{ ref('bronze_orders') }} o
JOIN {{ ref('bronze_order_items') }} oi
  ON o.order_id = oi.order_id
```

### Gold Layer (Trino → PostgreSQL)
```sql
-- Analytics and aggregations
SELECT 
    DATE_FORMAT(order_date, 'yyyy-MM') as month,
    category,
    SUM(sales) as total_sales,
    COUNT(DISTINCT customer_id) as unique_customers
FROM {{ ref('silver_fact_sales') }}
GROUP BY 1, 2
```

## 🧪 Testing Patterns

### Data Quality Tests
```yaml
models:
  - name: fact_sales
    tests:
      - unique:
          column_name: "order_id||product_id" 
      - not_null:
          column_name: [order_id, customer_id]
      - dbt_utils.accepted_range:
          column_name: payment_value
          min_value: 0
```

### Custom Test Macros
```sql
-- macros/test_revenue_positive.sql
{% macro test_revenue_positive(model) %}
  SELECT COUNT(*) FROM {{ model }}
  WHERE revenue < 0
{% endmacro %}
```

## 🔍 Debugging Quick Tips

### Common Issues
```bash
# Service not ready
docker-compose ps  # Check health status
docker-compose logs service-name

# dbt connection errors  
dbt debug --profile profile-name

# SQL compilation issues
dbt compile --models model-name

# Performance issues
dbt run --models model-name --profile spark --debug
```

### Log Locations
```bash
# Docker service logs
docker-compose logs -f trino
docker-compose logs -f spark-master

# dbt logs
tail -f logs/dbt.log

# Application logs inside containers
docker exec -it spark-master cat /opt/bitnami/spark/logs/spark-master.out
```

## 📈 Performance Optimization

### Query Optimization
```sql
-- Partition pruning
WHERE order_date >= '2023-01-01'

-- Predicate pushdown
SELECT customer_id, order_date
FROM large_table
WHERE status = 'completed'  -- Filter early
```

### Storage Optimization
```sql
-- Delta Lake optimization
OPTIMIZE delta.warehouse.silver.fact_sales
ZORDER BY (customer_id, order_date);

-- Vacuum old versions
VACUUM delta.warehouse.silver.fact_sales RETAIN 168 HOURS;
```

### dbt Configuration
```yaml
models:
  fact_sales:
    materialized: incremental
    partition_by: DATE(order_timestamp)
    cluster_by: [customer_id, product_category]
```

## 🎯 Learning Shortcuts

### Quick Wins
1. **Start Services**: `make build && make up`
2. **Load Data**: `cd ecom_analytics && make seed`
3. **Run Pipeline**: `make run_all`
4. **View Results**: Connect to PostgreSQL and query gold tables

### Key Concepts to Master
- **Medallion Architecture**: Bronze → Silver → Gold progression
- **Engine Selection**: Right tool for each job
- **dbt Incremental**: Efficient large dataset updates
- **Delta Lake**: ACID transactions for data lake
- **Cross-Engine**: Data flowing between different systems

### Must-Try Exercises
1. Add a new metric to Gold layer
2. Create a custom dbt test
3. Optimize a slow-running model
4. Add a new data source
5. Implement data quality monitoring

## 🔗 Quick Links

- **[📚 Complete Learning Materials](./LEARNING_INDEX.md)**
- **[🎯 Hands-On Tutorial](./HANDS_ON_TUTORIAL.md)**
- **[🏛️ Technical Deep Dive](./TECHNICAL_DEEP_DIVE.md)**
- **[📖 Best Practices](./BEST_PRACTICES.md)**

Keep this reference handy while working through the learning materials!
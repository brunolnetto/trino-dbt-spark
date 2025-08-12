# Learning Guide: Modern Data Engineering with Trino, dbt, and Spark

This project demonstrates a comprehensive modern data engineering stack that showcases best practices in data architecture, processing, and analytics. This guide will help you understand the key concepts and implementation patterns.

## 🏗️ Architecture Overview

This project implements a **Medallion Architecture** (Bronze → Silver → Gold) using multiple engines optimized for different workloads:

```
Source Data (CSV Seeds) → Bronze Layer (dbt) → Silver Layer (Spark) → Gold Layer (PostgreSQL)
                                                                              ↓
                                                                        Metabase (BI)
```

### Why This Architecture?

1. **Separation of Concerns**: Each layer has a specific purpose and processing engine
2. **Scalability**: Different engines can be scaled independently
3. **Performance**: Each engine is optimized for its workload
4. **Data Quality**: Progressive data refinement through layers

## 🔧 Technology Stack

### Core Components

| Component | Purpose | Why This Choice |
|-----------|---------|----------------|
| **Trino** | Distributed SQL query engine | Fast analytics across multiple data sources |
| **Apache Spark** | Big data processing | Efficient large-scale data transformations |
| **dbt** | Data transformation framework | Version-controlled, testable SQL transformations |
| **MinIO** | S3-compatible object storage | Cost-effective data lake storage |
| **Hive Metastore** | Metadata management | Schema registry for data lake |
| **Apache Iceberg** | ACID transactions for data lake | Reliable data versioning and updates |

### Supporting Infrastructure

- **dbt Seeds**: Source data in CSV format
- **PostgreSQL**: Analytics warehouse
- **Metabase**: Business intelligence and visualization
- **Docker Compose**: Containerized deployment

## 📊 Data Flow Deep Dive

### 1. Bronze Layer (Raw Data Ingestion)
**Engine**: Trino  
**Purpose**: Minimal processing, data lake ingestion  
**Format**: Iceberg tables in MinIO

```sql
-- Example: Bronze layer model
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM {{ source('landing_zone', 'olist_orders_dataset') }}
```

**Key Patterns**:
- Direct source system replication
- Minimal transformations
- Preserves all raw data
- Uses incremental materialization

### 2. Silver Layer (Data Transformation)
**Engine**: Spark  
**Purpose**: Data cleaning, standardization, dimensional modeling  
**Format**: Iceberg tables with ACID transactions

```sql
-- Example: Dimensional model in Silver
SELECT
    ro.order_id,
    ro.customer_id,
    roi.product_id,
    rop.payment_value
FROM {{ source("silver", "olist_orders") }} ro
JOIN {{ source("silver", "olist_order_items")}} roi
  ON ro.order_id = roi.order_id
```

**Key Patterns**:
- Star/snowflake schema design
- Data quality improvements
- Business rule applications
- Merge incremental strategy for updates

### 3. Gold Layer (Analytics Ready)
**Engine**: Trino + PostgreSQL  
**Purpose**: Business metrics and aggregations  
**Format**: PostgreSQL tables for fast BI queries

```sql
-- Example: Business metric aggregation
SELECT
    monthly,
    category,
    SUM(sales) AS total_sales,
    SUM(bills) AS total_bills,
    (SUM(sales) * 1.0 / SUM(bills)) AS values_per_bills
FROM daily_sales_categories
GROUP BY monthly, category
```

## 🛠️ dbt Implementation Patterns

### Multi-Profile Architecture

This project uses three dbt profiles for different layers:

```yaml
# profiles.yml
trino:     # Bronze layer
  type: trino
  database: warehouse
  schema: bronze

spark:     # Silver layer  
  type: spark
  method: thrift
  schema: silver

gold:      # Gold layer
  type: trino
  database: de_psql
  schema: gold
```

### Configuration Strategies

```yaml
# dbt_project.yml
models:
  bronze:
    +materialized: incremental
    +incremental_strategy: delete+insert
    +file_format: iceberg
    
  silver:
    +materialized: incremental
    +incremental_strategy: merge
    +file_format: iceberg
    
  gold:
    +materialized: table
```

## 🚀 Getting Started

### Prerequisites
- Docker and Docker Compose
- Python 3.8+
- Make utility

### Setup Steps

1. **Clone and prepare environment**:
```bash
git clone <repository>
cd trino-dbt-spark
cp .env.example .env  # Configure your environment
```

2. **Build and start infrastructure**:
```bash
make build
make up
```

3. **Prepare source data**:
```bash
# Load source CSV data
make seed
# Seeds will be automatically loaded into the warehouse
```

4. **Run the data pipeline**:
```bash
cd ecom_analytics
make run_all  # Runs: seed → bronze → silver → gold
```

### Pipeline Commands

```bash
# Individual layers
make run_bronze    # Trino profile, Bronze models
make run_silver    # Spark profile, Silver models  
make run_gold      # Gold profile, Analytics models

# Utilities
make docs          # Generate dbt documentation
make test          # Run dbt tests
```

## 💡 Key Learning Points

### 1. Engine Selection Strategy
- **Trino**: Fast interactive analytics, cross-source queries
- **Spark**: Large-scale transformations, complex business logic
- **PostgreSQL**: OLAP queries, BI tool integration

### 2. Data Lake Best Practices
- **Apache Iceberg format**: ACID transactions, time travel
- **Partitioning strategy**: Optimized for query patterns
- **Schema evolution**: Backward compatible changes

### 3. dbt Modeling Patterns
- **Incremental models**: Efficient large dataset updates
- **Source + staging pattern**: Separation of raw and clean data
- **Ref() function**: Dependency management and lineage

### 4. Infrastructure as Code
- **Docker Compose**: Reproducible multi-service environment
- **Environment variables**: Configuration management
- **Health checks**: Service dependency management

## 🔍 Advanced Concepts Demonstrated

### Cross-Engine Data Processing
The project shows how to leverage different engines for their strengths:
- Trino for fast federated queries
- Spark for heavy ETL workloads
- PostgreSQL for OLAP analytics

### Modern Data Stack Integration
- **ELT pattern**: Extract-Load-Transform with data lake
- **Schema-on-read**: Flexible data modeling
- **Separation of storage and compute**: Cost optimization

### Data Quality and Testing
```yaml
# Example dbt test
models:
  - name: fact_sales
    tests:
      - unique:
          column_name: "order_id||product_id"
      - not_null:
          column_name: order_id
```

## 🎯 Use Cases and Applications

This architecture pattern is ideal for:

1. **E-commerce Analytics**: Customer behavior, sales performance
2. **IoT Data Processing**: Sensor data ingestion and analysis
3. **Financial Services**: Transaction processing and risk analysis
4. **Multi-source Analytics**: Combining data from various systems

## 📚 Further Learning

To deepen your understanding:

1. **Explore the dbt documentation**: Generated with `make docs`
2. **Experiment with modifications**: Add new sources or transformations
3. **Study the Docker configurations**: Understand service interactions
4. **Review SQL patterns**: Different approaches in each layer

## 🔧 Troubleshooting Common Issues

### Service Dependencies
- Wait for health checks before running dbt commands
- Check service logs: `docker-compose logs <service-name>`

### Memory Issues
- Adjust Spark worker memory in docker-compose.yml
- Monitor resource usage: `docker stats`

### Connection Problems
- Verify network connectivity between services
- Check service ports and firewall settings

This project serves as an excellent foundation for learning modern data engineering practices and can be extended for various use cases and learning scenarios.
# Modern Data Engineering with Trino, dbt, and Spark

A comprehensive data engineering project demonstrating the **Medallion Architecture** (Bronze → Silver → Gold) using modern tools and best practices.

## 🚀 Quick Start

For immediate setup and exploration:

```bash
make build
make up
```

## 📚 Learning Materials

This project serves as a comprehensive learning resource for modern data engineering. Choose your learning path:

### 🎯 [Learning Index](./LEARNING_INDEX.md) - Start Here!
**Your complete guide to mastering this project** - includes learning paths for different experience levels and use cases.

### 📖 Core Learning Materials

| Resource | Purpose | Best For |
|----------|---------|----------|
| **[📋 Learning Guide](./LEARNING_GUIDE.md)** | Architecture overview and foundational concepts | Everyone - start here for understanding |
| **[🔧 Hands-On Tutorial](./HANDS_ON_TUTORIAL.md)** | Step-by-step practical exercises | Learning by building and experimenting |
| **[🏛️ Technical Deep Dive](./TECHNICAL_DEEP_DIVE.md)** | Advanced patterns and implementation details | Experienced engineers and architects |
| **[📖 Best Practices](./BEST_PRACTICES.md)** | Production-ready patterns and guidelines | Teams building production systems |

### 🎓 Quick Learning Paths

- **🚀 Quick Start (30 min)**: [Learning Guide](./LEARNING_GUIDE.md) → [Tutorial Exercises 1-2](./HANDS_ON_TUTORIAL.md)
- **🏗️ Architecture Focus (2-3 hrs)**: [Learning Guide](./LEARNING_GUIDE.md) → [Technical Deep Dive](./TECHNICAL_DEEP_DIVE.md)
- **🛠️ Hands-On Implementation (4-6 hrs)**: [Complete Tutorial](./HANDS_ON_TUTORIAL.md) → [Best Practices](./BEST_PRACTICES.md)

## 🏗️ Architecture Overview

This project implements a **Medallion Architecture** using multiple engines optimized for different workloads:

```
MySQL (Source) → Trino (Bronze) → Spark (Silver) → PostgreSQL (Gold) → Metabase (BI)
```

### Technology Stack
- **Trino**: Distributed SQL query engine for fast analytics
- **Apache Spark**: Big data processing and transformations  
- **dbt**: Data transformation framework with version control
- **Delta Lake**: ACID transactions and versioning for data lake
- **MinIO**: S3-compatible object storage
- **PostgreSQL**: Analytics warehouse for BI
- **Metabase**: Business intelligence and visualization

## 🎯 What You'll Learn

- **Modern Data Architecture**: Medallion pattern implementation
- **Multi-Engine Processing**: Leveraging different tools for optimal performance
- **Data Lake Engineering**: Delta Lake, partitioning, and optimization
- **dbt Best Practices**: Multi-profile setups, testing, and incremental models
- **Infrastructure as Code**: Docker Compose orchestration
- **Data Quality**: Testing frameworks and monitoring
- **Production Patterns**: CI/CD, security, and governance

## 🛠️ Getting Started

### Prerequisites
- Docker Desktop and Docker Compose
- Python 3.8+ (for dbt)
- Basic SQL knowledge
- 8GB+ RAM recommended

### Infrastructure Setup
```bash
make build  # Build all Docker containers
make up     # Start all services (wait 2-3 minutes for health checks)
```

### Data Pipeline Execution

```bash
cd ecom_analytics

# Complete pipeline execution
make run_all

# Or run individual layers
make run_bronze  # Trino → Delta Lake
make run_silver  # Spark transformations  
make run_gold    # Analytics → PostgreSQL
```

## 🏛️ Detailed Setup (Original Instructions)

### Prepare MySQL data

```sql
# copy CSV data to mysql container
# cd path/to/brazilian-ecommerce/
docker cp brazilian-ecommerce/ de_mysql:/tmp/
docker cp mysql_schemas.sql de_mysql:/tmp/

# login to mysql server as root
make to_mysql_root
CREATE DATABASE brazillian_ecommerce;
USE brazillian_ecommerce;
GRANT ALL PRIVILEGES ON *.* TO admin;
SHOW GLOBAL VARIABLES LIKE 'LOCAL_INFILE';
SET GLOBAL LOCAL_INFILE=TRUE;
# exit

# run commands
make to_mysql

source /tmp/mysql_schemas.sql;
show tables;

LOAD DATA LOCAL INFILE '/tmp/brazilian-ecommerce/olist_order_items_dataset.csv' INTO TABLE olist_order_items_dataset FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE '/tmp/brazilian-ecommerce/olist_order_payments_dataset.csv' INTO TABLE olist_order_payments_dataset FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE '/tmp/brazilian-ecommerce/olist_orders_dataset.csv' INTO TABLE olist_orders_dataset FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE '/tmp/brazilian-ecommerce/olist_products_dataset.csv' INTO TABLE olist_products_dataset FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE '/tmp/brazilian-ecommerce/product_category_name_translation.csv' INTO TABLE product_category_name_translation FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

SELECT * FROM olist_order_items_dataset LIMIT 10;
SELECT * FROM olist_order_payments_dataset LIMIT 10;
SELECT * FROM olist_orders_dataset LIMIT 10;
SELECT * FROM olist_products_dataset LIMIT 10;
SELECT * FROM product_category_name_translation LIMIT 10;
```


# Prepare data PostgreSQL
```bash
make to_psql

create database metabaseappdb;
create database ecom_analytics;
```

# Prepare delta-table on warehouse Data lake
```sql
SHOW catalogs;

SHOW SCHEMAS FROM warehouse;

CREATE SCHEMA IF NOT EXISTS warehouse.bronze WITH (location='s3a://warehouse/bronze');
DROP table if EXISTS warehouse.bronze.mytable;
CREATE TABLE warehouse.bronze.mytable (name varchar, id integer);
INSERT INTO warehouse.bronze.mytable VALUES ( 'John', 1), ('Jane', 2);
SELECT * FROM warehouse.bronze.mytable;

CREATE SCHEMA IF NOT EXISTS warehouse.silver WITH (location='s3a://warehouse/silver');

-- https://docs.getdbt.com/reference/resource-properties/external
-- https://github.com/dbt-labs/dbt-external-tables
dbt run-operation stage_external_sources --vars "ext_full_refresh: true"
```

# Run DBT
```bash
cd ecom_analytics
make run_bronze

make run_external
make run_silver
make run_gold
```

## 🎯 Use Cases and Applications

This architecture is ideal for:
- **E-commerce Analytics**: Customer behavior, sales performance, product insights
- **Multi-source Data Integration**: Combining data from various systems
- **Real-time + Batch Processing**: Hybrid processing patterns
- **Data Lake Implementation**: Modern lakehouse architecture
- **Cross-team Analytics**: Self-service analytics with governance

## 🔍 Key Features Demonstrated

- **Medallion Architecture**: Progressive data refinement through Bronze → Silver → Gold
- **Multi-Engine Optimization**: Right tool for each job (Trino for queries, Spark for ETL)
- **Delta Lake**: ACID transactions, time travel, and schema evolution
- **dbt Multi-Profile**: Engine-specific configurations and optimizations
- **Data Quality**: Comprehensive testing and validation frameworks
- **Infrastructure as Code**: Reproducible environments with Docker

## 🚀 Advanced Topics

Explore advanced patterns covered in the learning materials:
- Cross-engine data processing strategies
- Performance optimization techniques  
- Production deployment patterns
- Security and governance implementation
- Monitoring and alerting strategies
- Scaling and cost optimization

## 🤝 Contributing

This project serves as a learning resource. Contributions welcome:
- Documentation improvements
- Additional use case examples
- Performance optimizations
- Extended tutorials and exercises

## 📄 License

This project is open source and available for educational and commercial use.

## 🙏 Acknowledgments

- Brazilian E-commerce dataset by Olist
- Open source data engineering community
- dbt, Trino, Spark, and Delta Lake communities

---

**Ready to learn?** Start with the [📚 Learning Index](./LEARNING_INDEX.md) to choose your learning path!
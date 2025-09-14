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
| **[📋 Learning Guide](./docs/LEARNING_GUIDE.md)** | Architecture overview and foundational concepts | Everyone - start here for understanding |
| **[🔧 Hands-On Tutorial](./docs/HANDS_ON_TUTORIAL.md)** | Step-by-step practical exercises | Learning by building and experimenting |
| **[🏛️ Technical Deep Dive](./docs/TECHNICAL_DEEP_DIVE.md)** | Advanced patterns and implementation details | Experienced engineers and architects |
| **[📖 Best Practices](./docs/BEST_PRACTICES.md)** | Production-ready patterns and guidelines | Teams building production systems |

### 🎓 Quick Learning Paths

- **🚀 Quick Start (30 min)**: [Learning Guide](./docs/LEARNING_GUIDE.md) → [Tutorial Exercises 1-2](./docs/HANDS_ON_TUTORIAL.md)
- **🏗️ Architecture Focus (2-3 hrs)**: [Learning Guide](./docs/LEARNING_GUIDE.md) → [Technical Deep Dive](./docs/TECHNICAL_DEEP_DIVE.md)
- **🛠️ Hands-On Implementation (4-6 hrs)**: [Complete Tutorial](./docs/HANDS_ON_TUTORIAL.md) → [Best Practices](./docs/BEST_PRACTICES.md)

## 🏗️ Architecture Overview

This project implements a **Medallion Architecture** using multiple engines optimized for different workloads:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Source    │    │   Bronze    │    │   Silver    │    │    Gold     │    │     BI      │
│   (CSV)     │───>│  (Iceberg)  │───>│  (Iceberg)  │───>│(PostgreSQL) │───>│ (Metabase)  │
│             │    │             │    │             │    │             │    │             │
│ • Orders    │    │ • Raw Data  │    │ • Cleaned   │    │ • Analytics │    │ • Dashboard │
│ • Products  │    │ • Type Cast │    │ • Joined    │    │ • Aggregated│    │ • Reports   │
│ • Payments  │    │ • Validated │    │ • Enhanced  │    │ • Optimized │    │ • Self-Serve│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
      dbt               Trino            Spark           PostgreSQL         Metabase
     Seeds             Bronze            Silver             Gold              BI
```

### Technology Stack

| Component | Purpose | Version | Configuration |
|-----------|---------|---------|---------------|
| **🔄 dbt Core** | Data transformation & orchestration | 1.10.8+ | Multi-profile setup (Trino/Spark/PostgreSQL) |
| **⚡ Apache Spark** | Big data processing & ETL | 3.3 | Custom Docker build with Iceberg support |
| **🎯 Trino** | Distributed SQL query engine | 427 | Optimized for OLAP queries |
| **🧊 Apache Iceberg** | Data lake table format | Latest | ACID transactions, time travel, schema evolution |
| **💾 MinIO** | S3-compatible object storage | Latest | High-performance object storage |
| **🗄️ PostgreSQL** | Analytics data warehouse | 15 | Optimized for BI workloads |
| **📊 Metabase** | Business intelligence platform | v0.47.4 | Self-service analytics & dashboards |
| **🐝 Hive Metastore** | Metadata catalog | 3.0.0 | Schema registry for data lake |
| **🚀 Enhanced Makefile** | Production orchestration system | Custom | Error handling, monitoring, logging, rollback |

## 🎯 What You'll Learn

- **Modern Data Architecture**: Medallion pattern implementation
- **Multi-Engine Processing**: Leveraging different tools for optimal performance
- **Data Lake Engineering**: Apache Iceberg, partitioning, and optimization
- **dbt Best Practices**: Multi-profile setups, testing, and incremental models
- **Infrastructure as Code**: Docker Compose orchestration
- **Data Quality**: Testing frameworks and monitoring
- **Production Patterns**: CI/CD, security, and governance

## 📊 Dataset Overview

This project uses the **Brazilian E-Commerce Public Dataset by Olist**, a real-world dataset containing information about 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil.

### 📋 Data Schema

| Table | Records | Description |
|-------|---------|-------------|
| **🛒 Orders** | ~100k | Order information with status, timestamps, and customer references |
| **📦 Order Items** | ~112k | Individual items within orders (products, quantities, prices) |
| **💳 Payments** | ~103k | Payment information including method, installments, and values |
| **🏷️ Products** | ~32k | Product catalog with categories, dimensions, and weights |
| **🌐 Category Translation** | 71 | Portuguese to English category name mappings |

### 🔄 Data Flow by Layer

#### 🥉 **Bronze Layer** (Raw Data)
- **Purpose**: Ingest and preserve raw data with minimal transformations
- **Technology**: dbt + Trino → Apache Iceberg
- **Operations**: Type casting, basic validation, partitioning
- **Storage**: S3-compatible (MinIO) with Iceberg format

#### 🥈 **Silver Layer** (Cleaned & Enriched)
- **Purpose**: Clean, join, and enhance data for analytics
- **Technology**: dbt + Spark → Apache Iceberg  
- **Operations**: Data cleaning, joins, feature engineering, deduplication
- **Key Models**:
  - `dim_products`: Product dimension with category translations
  - `fact_sales`: Sales fact table with order, item, and payment data

#### 🥇 **Gold Layer** (Analytics-Ready)
- **Purpose**: Create business-specific aggregations and metrics
- **Technology**: dbt + PostgreSQL
- **Operations**: Aggregations, business metrics, performance optimization
- **Key Models**:
  - `sales_values_by_category`: Revenue analytics by product category

### 📈 Business Questions Answered

- **Sales Performance**: Revenue trends, seasonality, growth rates
- **Product Analytics**: Best-selling categories, pricing analysis
- **Customer Behavior**: Order patterns, payment preferences
- **Operational Metrics**: Delivery performance, order fulfillment

## 🛠️ Getting Started

### 🚀 Pipeline Orchestration

This project includes a **production-ready orchestration system** with comprehensive monitoring, error handling, and operational capabilities. See the **[📋 Orchestration Guide](./ORCHESTRATION_GUIDE.md)** for detailed information about:

- **Error Handling**: Automatic backup creation, cleanup on failures, and rollback capabilities
- **Monitoring**: Real-time pipeline monitoring, performance tracking, and detailed reporting
- **Validation**: Infrastructure health checks, dependency validation, and data quality gates
- **Logging**: Structured logging with execution IDs, timestamps, and comprehensive audit trails

#### Quick Orchestration Commands
```bash
# Execute complete pipeline with monitoring
make run_all

# Monitor pipeline in real-time
make monitor_pipeline

# Check pipeline status and health
make status

# Generate performance reports
make performance_report

# Rollback on failures
make rollback_layer LAYER=bronze|silver|gold
```

### Prerequisites
- **Docker Desktop** and Docker Compose (v2.0+)
- **Python 3.11+** (for dbt development)
- **8GB+ RAM** recommended for full stack
- **Basic SQL knowledge** for data modeling
- **Git** for version control

### Infrastructure Setup
```bash
make build  # Build all Docker containers (~5-10 minutes)
make up     # Start all services (wait 2-3 minutes for health checks)
```

### 🐳 Service Details

| Service | Port | Purpose | Health Check | Resources |
|---------|------|---------|--------------|-----------|
| **PostgreSQL** | 5432 | Data warehouse & metadata | `pg_isready` | 2GB RAM, 2 CPU |
| **MinIO** | 9000/9001 | Object storage (S3-compatible) | `/minio/health/live` | Default |
| **Hive Metastore** | 9083 | Schema registry | `nc -z localhost 9083` | 4GB RAM, 2 CPU |
| **Trino** | 8080 | Query engine | `/v1/info/state` | 8GB RAM, 4 CPU |
| **Spark Master** | 8081 | Spark cluster coordinator | `curl spark-master:8080` | Default |
| **Spark Workers** | N/A | Distributed processing (2 replicas) | Process check | 2GB RAM, 1 CPU each |
| **Spark Thrift** | 4040/10000 | SQL interface for Spark | Process check | Default |
| **Metabase** | 3000 | Business intelligence | `/api/health` | 2GB RAM, 1 CPU |

### 🔧 Environment Configuration

The project uses environment variables for configuration. Copy and customize:

```bash
cp .env.template .env
# Edit .env with your specific settings if needed
```

Key environment variables:
- **Database Credentials**: PostgreSQL connection details
- **Object Storage**: MinIO access keys and endpoints  
- **Resource Limits**: Memory and CPU allocations
- **dbt Settings**: Profile and target configurations

### dbt Profile Configuration
Before running the data pipeline, you need to set up your dbt profiles:

```bash
cd ecom_analytics
cp profiles.yml.example profiles.yml
# Edit profiles.yml if needed (default configuration should work with Docker setup)
```

**Note**: The `profiles.yml` file contains connection credentials and is excluded from version control for security.

### Data Pipeline Execution

The data pipeline uses dbt seeds to load the initial data and then processes it through the medallion architecture layers:

```bash
cd ecom_analytics

# Complete pipeline execution (including data seeding)
make run_all

# Or run individual steps:
make seed            # Load source CSV data into warehouse
make run_bronze      # Transform data in Bronze layer
make run_external    # Set up external tables
make run_silver      # Transform Bronze → Silver
make run_gold        # Transform Silver → Gold

# For incremental processing (skip full refresh):
make run_all FULL_REFRESH=""
```

## 🏛️ Pipeline Architecture

### Data Flow
1. **Source Ingestion**: CSV files loaded via dbt seeds into PostgreSQL staging area
2. **Bronze Layer**: Raw data captured in Iceberg format with basic validation (Trino + dbt)
3. **Silver Layer**: Business transformations and data quality rules applied (Spark + dbt)
4. **Gold Layer**: Analytics-ready aggregations created in PostgreSQL (PostgreSQL + dbt)
5. **BI Layer**: Metabase connects to PostgreSQL for visualization and self-service analytics

### 🎨 dbt Model Architecture

#### 📁 **Models Directory Structure**
```
ecom_analytics/models/
├── bronze/           # Raw data ingestion (Trino → Iceberg)
│   ├── olist_orders.sql
│   ├── olist_order_items.sql
│   ├── olist_order_payments.sql
│   ├── olist_products.sql
│   └── schema.yml
├── silver/           # Cleaned & enriched data (Spark → Iceberg)
│   ├── dim_products.sql
│   ├── fact_sales.sql
│   └── schema.yml
└── gold/             # Analytics aggregations (PostgreSQL)
    ├── sales_values_by_category.sql
    └── schema.yml
```

#### 🥉 **Bronze Layer Models**
- **Materialization**: `incremental` with `delete+insert` strategy
- **Storage**: Apache Iceberg format in MinIO
- **Partitioning**: By timestamp columns for query performance
- **Purpose**: Preserve raw data with minimal transformations

| Model | Unique Key | Partitioning | Description |
|-------|------------|--------------|-------------|
| `olist_orders` | `order_id` | `order_purchase_timestamp` | Order lifecycle and status tracking |
| `olist_order_items` | `order_id, order_item_id` | `shipping_limit_date` | Product items within each order |
| `olist_order_payments` | `order_id, payment_sequential` | `payment_type` | Payment methods and installments |
| `olist_products` | `product_id` | Static | Product catalog with dimensions |

#### 🥈 **Silver Layer Models**
- **Materialization**: `incremental` with `merge` strategy
- **Storage**: Apache Iceberg format with optimizations
- **Processing**: Spark for complex joins and transformations
- **Purpose**: Clean, join, and enrich data for analytics

| Model | Description | Key Transformations |
|-------|-------------|-------------------|
| `dim_products` | Product dimension table | • Category name translation (PT→EN)<br>• Product metrics calculation<br>• Data quality validation |
| `fact_sales` | Comprehensive sales fact table | • Orders + Items + Payments join<br>• Revenue calculations<br>• Date dimension enrichment |

#### 🥇 **Gold Layer Models**
- **Materialization**: `table` for fast query performance
- **Storage**: PostgreSQL for BI tool optimization
- **Purpose**: Business-specific aggregations and KPIs

| Model | Description | Business Value |
|-------|-------------|----------------|
| `sales_values_by_category` | Revenue analysis by product category | • Category performance ranking<br>• Revenue trends over time<br>• Market share analysis |

### Data Quality
- Bronze: Raw data validation and type casting
- Silver: Business rules and referential integrity
- Gold: Aggregation and final validation

For detailed technical implementation, see the [Technical Deep Dive](./docs/TECHNICAL_DEEP_DIVE.md).

## 🔍 Monitoring & Access Points

### 🌐 Service URLs
Once the stack is running, access the following interfaces:

| Service | URL | Purpose | Credentials |
|---------|-----|---------|-------------|
| **Trino UI** | [http://localhost:8080](http://localhost:8080) | Query monitoring & performance | None required |
| **Spark Master UI** | [http://localhost:8081](http://localhost:8081) | Spark cluster status | None required |
| **Spark Application UI** | [http://localhost:4040](http://localhost:4040) | Active job monitoring | None required |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001) | Object storage management | `minio`/`minio123` (default) |
| **Metabase** | [http://localhost:3000](http://localhost:3000) | BI dashboards | Setup on first visit |

### 🔧 Development Tools
```bash
# Check service health
make status

# View logs for specific service
docker-compose logs -f trino
docker-compose logs -f spark-master

# Connect to PostgreSQL
make to_psql

# Run dbt commands
cd ecom_analytics
dbt debug                    # Test connections
dbt run --select bronze     # Run specific layer
dbt test                     # Execute data quality tests
dbt docs generate && dbt docs serve  # Generate documentation
```

## 🚨 Troubleshooting

### Common Issues & Solutions

#### 🐳 **Docker Issues**
```bash
# Issue: Services fail to start
# Solution: Check available resources
docker system df
docker system prune  # Clean up if needed

# Issue: Port conflicts
# Solution: Check for conflicting services
lsof -i :8080  # Check if port is in use
```

#### 💾 **Memory Issues**
```bash
# Issue: Spark/Trino OOM errors
# Solution: Adjust memory allocation in docker-compose.yml
# Or reduce dataset size for development

# Issue: Docker Desktop memory limit
# Solution: Increase Docker Desktop memory allocation (8GB minimum)
```

#### 🔗 **Connection Issues**
```bash
# Issue: dbt cannot connect to databases
# Solution: Verify service health and wait for startup
docker-compose ps  # Check service status
docker-compose logs -f trino  # Check for startup completion

# Issue: Metabase cannot connect to PostgreSQL
# Solution: Ensure PostgreSQL is healthy before Metabase starts
```

#### 📊 **Data Pipeline Issues**
```bash
# Issue: dbt seed fails
# Solution: Check CSV file encoding and format
cd ecom_analytics
dbt debug  # Verify connections

# Issue: Incremental models failing
# Solution: Run with full refresh first
dbt run --full-refresh --select bronze

# Issue: Spark jobs hanging
# Solution: Check Spark UI for blocked stages
# URL: http://localhost:4040
```

#### 🗄️ **Storage Issues**
```bash
# Issue: MinIO bucket not accessible
# Solution: Verify MinIO initialization
docker-compose logs minio-init

# Issue: Iceberg table corruption
# Solution: Clear data and rebuild
docker-compose down -v
make up && cd ecom_analytics && make run_all
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
- **Apache Iceberg**: ACID transactions, time travel, and schema evolution
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

## ⚡ Performance & Production Considerations

### 🎯 **Performance Tuning**

#### Spark Optimization
```bash
# Adjust Spark configurations in docker/spark/conf/spark-defaults.conf
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
spark.serializer=org.apache.spark.serializer.KryoSerializer
```

#### Iceberg Optimization
```sql
-- Partition strategies for large tables
{{ config(partition_by=['year(order_purchase_timestamp)', 'month(order_purchase_timestamp)']) }}

-- Clustering for frequently filtered columns
{{ config(clustered_by=['customer_id'], buckets=32) }}
```

#### Trino Query Optimization
```sql
-- Use appropriate data types
-- Leverage partition elimination
-- Use EXPLAIN ANALYZE for query profiling
```

### 🏭 **Production Deployment**

#### Infrastructure Scaling
- **Spark**: Scale workers based on workload (`deploy.replicas`)
- **Trino**: Add coordinator and worker nodes for query performance
- **Storage**: Use distributed object storage (AWS S3, Azure Blob, GCS)
- **Database**: Consider PostgreSQL clustering for high availability

#### Security Considerations
```yaml
# production.yml additions
environment:
  - ENABLE_TLS=true
  - AUTHENTICATION_METHOD=LDAP
secrets:
  - db_password
  - s3_access_key
  - s3_secret_key
```

#### Monitoring Stack
```yaml
# Add to docker-compose.yml for production
services:
  prometheus:
    image: prom/prometheus
  grafana:
    image: grafana/grafana
  alertmanager:
    image: prom/alertmanager
```

### 📊 **Data Governance**

#### Data Quality Framework
```sql
-- dbt tests for data validation
{{ config(tests=['unique', 'not_null', 'accepted_values']) }}

-- Custom data quality checks
SELECT * FROM {{ ref('fact_sales') }} 
WHERE total_amount < 0 OR order_date > CURRENT_DATE
```

#### Lineage & Documentation
```bash
# Generate comprehensive documentation
dbt docs generate
dbt docs serve --port 8082

# Data lineage visualization available at http://localhost:8082
```

### 🔄 **CI/CD Pipeline**
```yaml
# .github/workflows/data-pipeline.yml
name: Data Pipeline CI/CD
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run dbt tests
        run: dbt test --profiles-dir .
```

## 📁 Project Structure

```
trino-dbt-spark/
├── 🐳 Docker Infrastructure
│   ├── docker-compose.yml              # Multi-service orchestration
│   ├── .env.template                   # Environment configuration template
│   └── docker/                         # Service-specific configurations
│       ├── hive-metastore/             # Metadata catalog setup
│       ├── minio/                      # Object storage initialization
│       ├── psql/                       # PostgreSQL init scripts
│       ├── spark/                      # Custom Spark build & config
│       └── trino/                      # Query engine configuration
│
├── 📊 Analytics Project (dbt)
│   └── ecom_analytics/                 # Main dbt project
│       ├── dbt_project.yml             # Project configuration
│       ├── profiles.yml.example        # Connection profiles template
│       ├── models/                     # Data transformation models
│       │   ├── bronze/                 # Raw data ingestion (Trino)
│       │   ├── silver/                 # Cleaned data (Spark)
│       │   └── gold/                   # Analytics aggregations (PostgreSQL)
│       ├── seeds/                      # Source CSV datasets
│       ├── tests/                      # Data quality tests
│       ├── macros/                     # Reusable SQL functions
│       └── snapshots/                  # Slowly changing dimensions
│
├── 📚 Documentation
│   ├── README.md                       # This comprehensive guide
│   └── docs/                           # Detailed learning materials
│       ├── LEARNING_INDEX.md           # Learning path navigator
│       ├── LEARNING_GUIDE.md           # Architecture fundamentals
│       ├── HANDS_ON_TUTORIAL.md        # Practical exercises
│       ├── TECHNICAL_DEEP_DIVE.md      # Advanced implementation
│       ├── BEST_PRACTICES.md           # Production guidelines
│       └── QUICK_REFERENCE.md          # Command cheat sheet
│
├── 🔧 Development Tools
│   ├── Makefile                        # Automation commands
│   ├── pyproject.toml                  # Python dependencies
│   ├── uv.lock                         # Dependency lock file
│   └── .github/                        # GitHub workflows & templates
└── 🗃️ Configuration
    ├── .gitignore                      # Version control exclusions
    └── .python-version                 # Python version specification
```

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
- dbt, Trino, Spark, and Apache Iceberg communities

---

**Ready to learn?** Start with the [📚 Learning Index](./docs/LEARNING_INDEX.md) to choose your learning path!

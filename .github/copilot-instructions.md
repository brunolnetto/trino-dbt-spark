# AI Agent Instructions for trino-dbt-spark

This project implements a Modern Data Engineering stack using Trino, dbt, and Spark following the Medallion Architecture pattern.

## Architecture & Data Flow

### Core Architecture
- **Medallion Architecture**: Data flows through Bronze (raw) → Silver (cleaned) → Gold (business) layers
- **Storage Pattern**: 
  - Bronze/Silver: Apache Iceberg tables in MinIO (S3) for ACID compliance and versioning
  - Gold: PostgreSQL for optimized analytics queries
- **Processing Strategy**:
  - Bronze: Minimal processing, schema validation (Trino)
  - Silver: Heavy transformations, joins, deduplication (Spark)
  - Gold: Business metrics, aggregations (PostgreSQL)

### Design Principles
- Raw data preservation in Bronze for auditability
- Progressive data enhancement through layers
- Engine selection optimized per workload
- Clear data contracts between layers

## Key Conventions

### dbt Models Structure
- `models/bronze/`: Raw data ingestion, 1:1 mapping with source, using Iceberg
- `models/silver/`: Cleaned dimension/fact tables with relationships
- `models/gold/`: Business-specific aggregations in PostgreSQL

### Model Configuration Patterns
```yaml
# Bronze layer - Raw ingestion (models/bronze/)
config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    file_format='iceberg',
    meta={
        'layer': 'bronze',
        'owner': 'data_engineering'
    }
)

# Silver layer - Curated data (models/silver/)
config(
    materialized='incremental',
    unique_key='<primary_key>',
    incremental_strategy='merge',
    partition_by=['<date_column>'],
    clustered_by=['<join_keys>'],
    buckets=16,
    meta={
        'layer': 'silver',
        'owner': 'data_engineering'
    }
)
```

## Development Workflow

### Local Setup & Pipeline Execution
```bash
make build            # Build containers
make up              # Start services
cd ecom_analytics    
make run_all         # Full pipeline execution
make test            # Run dbt tests

# Selective Processing
make run_bronze      # Process Bronze layer only
make run_silver      # Process Silver layer only
make run_gold        # Process Gold layer only
make run_all FULL_REFRESH=""  # Incremental processing
```

### Common Development Tasks

#### Adding New Models
1. **Bronze Models**: 
   - Copy pattern from `models/bronze/olist_orders.sql`
   - Add source definition in `models/bronze/sources.yml`
   - Always preserve raw data structure

2. **Silver Models**:
   - Follow pattern in `models/silver/fact_sales.sql` 
   - Implement proper incremental logic
   - Define clear grain in documentation

3. **Data Quality**:
   - Mandatory schema tests in `schema.yml`
   - Generic tests in `tests/generic/`
   - Custom tests per business rules

## Integration Points
- **MinIO (Data Lake)**:
  - Endpoint: `MINIO_URL` environment variable
  - Credentials: `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`
  - Pre-hooks handle S3 authentication in models
  
- **Spark Configuration**:
  - Connection settings in dbt models
  - Pre-hooks for S3 authentication
  - Partitioning and clustering configs

- **PostgreSQL (DW)**:
  - Connection profiles in `profiles.yml`
  - Optimized for analytics queries
  - Used for Gold layer tables

## Project Organization
- `/ecom_analytics/`: dbt project root
  - `models/<layer>/`: Layered transformation logic
  - `tests/generic/`: Reusable test suites
  - `macros/`: Utility functions
- `/docker/`: Service configurations
  - `trino/`: Query engine with Iceberg catalog
  - `spark/`: Processing engine configuration
  - `hive-metastore/`: Metadata service for Iceberg
  - `psql/`: Analytics database (Gold layer)
  - `minio/`: S3-compatible storage
- `/docs/`: Implementation guides

## Infrastructure Notes

### Service Configuration
- **Hive Metastore**: Central metadata service for Iceberg tables
  - Connection: `thrift://hive-metastore:9083`
  - Backend: PostgreSQL database
  
- **MinIO/S3**: Object storage for Bronze/Silver layers
  - Internal endpoint: `http://minio:9000`
  - External endpoint: Configure via `MINIO_URL`
  - Credentials via environment variables

- **Spark**: Processing engine for transformations
  - Iceberg integration via Spark extensions
  - S3 access configured via pre-hooks
  - Optimized for large-scale processing

- **Trino**: Query engine for data lake
  - Iceberg catalog configuration
  - PostgreSQL connector for Gold layer
  - Direct MinIO integration

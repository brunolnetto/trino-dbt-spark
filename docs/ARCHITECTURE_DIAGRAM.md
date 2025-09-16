# 🏗️ Multi-Engine Data Engineering Architecture

## Architecture Overview for Andreas Kretz

This project demonstrates a **production-ready multi-engine data engineering architecture** that seamlessly integrates **dbt**, **Trino**, and **Spark** following the **Medallion Architecture** pattern.

## 🎯 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           MULTI-ENGINE DATA ENGINEERING STACK                            │
│                                   (Educational Demo)                                     │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌───────────────┐    ┌────────────────┐    ┌──────────────┐    ┌─────────────┐
│   📊 DATA   │    │   🥉 BRONZE  │    │   🥈 SILVER   │    │   🥇 GOLD    │    │   📈 BI     │
│   SOURCES   │───>│    LAYER      │───>│    LAYER       │──> │    LAYER     │───>│   LAYER     │
│             │    │               │    │                │    │              │    │             │
│• CSV Files  │    │• Raw Ingestion│    │• Data Cleaning │    │• Aggregations│    │• Dashboards │
│• E-commerce │    │• Type Casting │    │• Joins         │    │• KPIs        │    │• Self-serve │
│• Orders     │    │• Validation   │    │• Enrichment    │    │• Analytics   │    │• Reports    │
│• Products   │    │• Partitioning │    │• Deduplication │    │• Metrics     │    │             │
│• Payments   │    │               │    │                │    │              │    │             │
└─────────────┘    └───────────────┘    └────────────────┘    └──────────────┘    └─────────────┘
                            │                    │                    │                  │
                    ┌───────▼────────┐  ┌────────▼────────┐  ┌────────▼─────────┐  ┌─────▼───────┐
                    │   🎯 TRINO    │  │   ⚡ SPARK      │  │   🐘 POSTGRES   │  │ 📊 METABASE │
                    │  Query Engine  │  │  Compute Engine │  │   Data Warehouse │  │    BI Tool  │
                    │                │  │                 │  │                  │  │             │
                    │• OLAP Queries  │  │• ETL Processing │  │• Analytics DB    │  │• Viz Layer  │
                    │• Federation    │  │• Complex Joins  │  │• OLTP Optimized  │  │• Dashboards │
                    │• Fast Reads    │  │• Large Scale    │  │• BI Performance  │  │• Self-serve │
                    └────────────────┘  └─────────────────┘  └──────────────────┘  └─────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                               🧊 STORAGE & COMPUTE LAYER                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐    ┌───────────────┐    ┌────────────────┐    ┌────────────────┐
│   📦 MinIO   │    │ 🧊 ICEBERG   │    │ 🔄 dbt CORE   │     │ 🐳 DOCKER     │
│   S3 Storage │    │ Table Format  │    │ Orchestrator   │    │ Infrastructure │
│              │    │               │    │                │    │                │
│• Object Store│<──>│• ACID Trans   │<──>│• Multi-Profile │◄──▶│• Service Mesh │
│• Data Lake   │    │• Time Travel  │    │• Layer Control │    │• Health Check  │
│• Partitions  │    │• Schema Evol  │    │• Testing       │    │• Auto-scaling  │
└──────────────┘    └──────────────┘     └────────────────┘    └────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                📋 dbt ORCHESTRATION FLOW                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘

    SEEDS                     BRONZE                    SILVER                     GOLD
┌─────────────┐        ┌─────────────────┐      ┌─────────────────┐       ┌─────────────────┐
│ CSV → dbt   │───────▶│ dbt + TRINO    │─────▶│ dbt + SPARK     │─────▶│ dbt + POSTGRES  │
│             │        │ ↓ Iceberg       │      │ ↓ Iceberg       │       │ ↓ Tables        │
│• Raw Files  │        │• olist_orders   │      │• dim_products   │       │• sales_by_cat   │
│• Type Hints │        │• olist_items    │      │• fact_sales     │       │• kpi_dashboard  │
│• Validation │        │• olist_payments │      │• clean_data     │       │• aggregations   │
└─────────────┘        └─────────────────┘      └─────────────────┘       └─────────────────┘
     │                         │                         │                         │
     ▼                         ▼                         ▼                         ▼
┌─────────────┐        ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│Profile:     │        │Profile: trino   │      │Profile: spark   │      │Profile: gold    │
│bronze       │        │Port: 8081      │      │Port: 10000     │      │Port: 5432      │
│Method: spark│        │DB: warehouse   │      │Method: thrift  │      │DB: analytics   │
└─────────────┘        └─────────────────┘      └─────────────────┘      └─────────────────┘
```

## 💡 Key Technical Innovations

### 🎯 **Multi-Engine Optimization**

- **Trino**: Optimized for OLAP queries and data federation
- **Spark**: Heavy ETL processing and complex transformations  
- **PostgreSQL**: Analytics-optimized for BI tools
- **dbt**: Orchestrates across all engines with profile switching

### 🏗️ **Medallion Architecture Benefits**

```
Bronze (Raw) ────▶ Silver (Cleaned) ────▶ Gold (Analytics)
     │                    │                      │
   Trino              Spark SQL             PostgreSQL
     │                    │                      │
  Iceberg             Iceberg               Structured
```

### ⚡ **Performance Patterns**

- **Engine Selection**: Right tool for each workload
- **Storage Strategy**: Iceberg for ACID + time travel
- **Query Optimization**: Engine-specific configurations
- **Scaling**: Independent engine scaling based on demand

## 🔧 Technical Implementation

### Docker Services Stack

```yaml
services:
  - trino:427         # Query federation
  - spark:3.5.1       # ETL processing  
  - postgres:15       # Analytics DB
  - minio:latest      # S3-compatible storage
  - iceberg-rest      # Metadata catalog
  - metabase:0.47.4   # BI visualization
```

### dbt Multi-Profile Configuration

```yaml
profiles:
  bronze:   spark   → port 10000 (thrift)
  silver:   spark   → port 10000 (thrift) 
  gold:     spark   → port 10000 (thrift)
  trino:    trino   → port 8081 (query)
```

### Data Flow Integration

```sql
-- Bronze: Raw ingestion with Trino
{{ config(materialized='incremental', engine='trino') }}

-- Silver: Complex joins with Spark  
{{ config(materialized='incremental', engine='spark') }}

-- Gold: Analytics with PostgreSQL
{{ config(materialized='table', engine='postgresql') }}
```

## 🎓 Educational Value

This architecture demonstrates:

✅ **Real-world Patterns**: Production-ready multi-engine setup
✅ **Modern Stack**: Latest tools (Iceberg, dbt 1.10+, Trino 427)
✅ **Best Practices**: Testing, documentation, monitoring
✅ **Scalability**: Independent scaling per layer
✅ **Flexibility**: Engine optimization per workload

## 🚀 Getting Started

```bash
# Complete setup in 3 commands
make build    # ~5 min: Build all containers
make up       # ~2 min: Start all services  
make run_all  # ~10 min: Execute full pipeline
```

## 📊 Success Metrics

**✅ Seed Ingestion**: CSV → dbt → Spark/Trino
**✅ Bronze Layer**: Trino → Iceberg (100K+ records)
**✅ Silver Layer**: Spark → Complex joins & cleaning
**✅ Gold Layer**: PostgreSQL → Analytics aggregations
**✅ BI Integration**: Metabase → Self-service dashboards

---

**Result**: A complete, working demonstration of modern data engineering with seamless dbt integration across Trino, Spark, and PostgreSQL engines.

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
Source CSVs → dbt Seeds → Apache Iceberg (Bronze) → Spark (Silver) → PostgreSQL (Gold) → Metabase (BI)
```

### Technology Stack
- **dbt**: Data transformation framework and pipeline orchestration
- **Apache Spark**: Big data processing and transformations
- **Apache Iceberg**: ACID transactions and versioning for data lake
- **MinIO**: S3-compatible object storage
- **PostgreSQL**: Analytics warehouse for BI
- **Metabase**: Business intelligence and visualization
- **Trino**: Distributed SQL query engine (optional for direct querying)

## 🎯 What You'll Learn

- **Modern Data Architecture**: Medallion pattern implementation
- **Multi-Engine Processing**: Leveraging different tools for optimal performance
- **Data Lake Engineering**: Apache Iceberg, partitioning, and optimization
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
1. Source CSV files are loaded via dbt seeds into the data warehouse
2. Bronze layer captures the raw data in Iceberg format
3. Silver layer applies business transformations and data quality rules
4. Gold layer creates analytics-ready views in PostgreSQL
5. Metabase connects to PostgreSQL for visualization

### Data Quality
- Bronze: Raw data validation and type casting
- Silver: Business rules and referential integrity
- Gold: Aggregation and final validation

For detailed technical implementation, see the [Technical Deep Dive](./TECHNICAL_DEEP_DIVE.md).

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

**Ready to learn?** Start with the [📚 Learning Index](./LEARNING_INDEX.md) to choose your learning path!
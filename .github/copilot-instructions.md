# AI Agent Instructions for trino-dbt-spark

This project implements a Modern Data Engineering stack using Trino, dbt, and Spark following the Medallion Architecture pattern.

## Architecture & Data Flow
- **Medallion Architecture**: Bronze (raw) → Silver (cleaned) → Gold (business) layers
- **Data Pipeline**: CSV seeds → Bronze (dbt, Trino, Iceberg, MinIO) → Silver (Spark, Iceberg) → Gold (PostgreSQL, Trino) → Metabase (BI)
- **Engine Selection**: Each layer uses the optimal engine for its workload; see `dbt_project.yml` and `profiles.yml` for configuration.
- **Storage**: Bronze/Silver in Iceberg tables on MinIO (S3) via REST catalog; Gold in PostgreSQL

✅ **Modernized Architecture**: Hive Metastore removed! Now using:
- **Iceberg REST Catalog**: Fast, lightweight metadata management (replaces Hive Metastore)
- **Pre-built Spark Images**: `tabulario/spark-iceberg:3.5.1_1.4.3` for faster builds
- **Simplified Dependencies**: No more complex Hive builds - sub-5 minute setup
- **Clean Configuration**: REST catalog endpoints, environment-driven credentials

## Developer Workflow
- **Build/Start**: `docker-compose up -d` (fast startup, no builds needed)
- **Core Services**: PostgreSQL, MinIO, Iceberg REST, Trino start in ~2 minutes  
- **Pipeline Execution**: `cd ecom_analytics && make run_all` (full pipeline), or `make run_bronze`, `make run_silver`, `make run_gold` for layer-specific runs
- **Data Seeding**: `make seed` loads CSVs from `seeds/`
- **Testing**: `make test` runs dbt tests; schema and generic tests in `models/*/schema.yml` and `tests/generic/`
- **Debugging**: Use `dbt run --models <model> --debug` and inspect compiled SQL in `target/compiled/`
- **Docs**: `make docs` generates documentation (see `docs/`)

## Key Conventions & Patterns
- **dbt Models**:
  - `models/bronze/`: 1:1 source mapping, incremental (delete+insert), partitioned by business key
  - `models/silver/`: Fact/dim models, incremental (merge), partitioned/clustered for query optimization
  - `models/gold/`: Analytics, materialized as tables, optimized for BI
- **Testing**: Mandatory not-null, uniqueness, referential integrity in `schema.yml`; reusable business tests in `tests/generic/`
- **Profiles**: Multi-engine setup in `profiles.yml` (Trino for Bronze, Spark for Silver, PostgreSQL for Gold)
- **Integration**:
  - MinIO/S3: Centralized config via env vars (`MINIO_URL`, etc.)
  - Iceberg REST Catalog: Fast metadata management for Iceberg tables
  - Trino: Federated queries, connects to both Iceberg and PostgreSQL
  - Spark: Heavy ETL using pre-built tabulario/spark-iceberg images
  - Metabase: Connects to Gold layer for BI

## Infrastructure & Configuration
- **Docker Compose**: All services orchestrated; see `docker-compose.yml` and `docker/` for service configs
- **Environment Variables**: All credentials and endpoints managed via env vars; avoid hardcoding
- **Health Checks**: Service dependencies managed via health checks in compose

## Examples
- **Bronze Model**: `models/bronze/olist_orders.sql` (incremental, partitioned)
- **Silver Model**: `models/silver/fact_sales.sql` (business logic, merge strategy)
- **Gold Model**: `models/gold/sales_values_by_category.sql` (analytics, table materialization)
- **Test**: `models/silver/schema.yml` (not_null, unique, accepted_range)
- **Pipeline Command**:
  ```bash
  docker-compose up -d
  cd ecom_analytics && make run_all
  ```

## Tips for AI Agents
- Always reference engine-specific configs in `profiles.yml` and model configs in `dbt_project.yml`
- Use layer-specific patterns for incremental logic and partitioning
- Validate all new models with schema and generic tests
- Prefer environment variables for all credentials and endpoints
- Document new models and tests in `docs/` and `schema.yml`

## Known Issues & Alternatives
- **Spark Build Issue**: Current Spark setup depends on slow Hive Metastore build
  - **Quick Alternative**: Use `tabulario/spark-iceberg` pre-built image
  - **Recommended Fix**: Replace Hive Metastore with Iceberg REST catalog
  - **Temporary Workaround**: Use Trino for all layers until Spark is optimized
- **dbt Environment**: UV/dbt setup may hang - use direct SQL for prototyping first

## Modernization Complete ✅
The project has been **successfully modernized** with:
- **Eliminated Dependencies**: Hive Metastore completely removed
- **Fast Startup**: Core services in ~2 minutes (vs 30+ minutes previously)
- **Modern Architecture**: Iceberg REST catalog for metadata management
- **Pre-built Images**: Using `tabulario/spark-iceberg:3.5.1_1.4.3` 
- **Simplified Configuration**: Environment-driven, no complex builds needed

The "awful dependency" (Hive Metastore) causing 30+ minute builds has been completely eliminated!

---
If any section is unclear or missing, please provide feedback for further refinement.

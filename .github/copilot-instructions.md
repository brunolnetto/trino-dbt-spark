# AI Agent Instructions for trino-dbt-spark

This project implements a Modern Data Engineering stack using Trino, dbt, and Spark following the Medallion Architecture pattern.

## Architecture & Data Flow
- **Medallion Architecture**: Bronze (raw) → Silver (cleaned) → Gold (business) layers
- **Data Pipeline**: CSV seeds → Bronze (dbt, Trino, Iceberg, MinIO) → Silver (Spark, Iceberg) → Gold (PostgreSQL, Trino) → Metabase (BI)
- **Engine Selection**: Each layer uses the optimal engine for its workload; see `dbt_project.yml` and `profiles.yml` for configuration.
- **Storage**: Bronze/Silver in Iceberg tables on MinIO (S3); Gold in PostgreSQL

## Developer Workflow
- **Build/Start**: `make build` (containers), `make up` (services)
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
  - Hive Metastore: Metadata for Iceberg tables
  - Trino: Federated queries, connects to both Iceberg and PostgreSQL
  - Spark: Heavy ETL, reads/writes Iceberg
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
  make build && make up
  cd ecom_analytics && make run_all
  ```

## Tips for AI Agents
- Always reference engine-specific configs in `profiles.yml` and model configs in `dbt_project.yml`
- Use layer-specific patterns for incremental logic and partitioning
- Validate all new models with schema and generic tests
- Prefer environment variables for all credentials and endpoints
- Document new models and tests in `docs/` and `schema.yml`

---
If any section is unclear or missing, please provide feedback for further refinement.

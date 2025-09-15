# AI Agent Instructions for trino-dbt-spark

This project implements a Modern Data Engineering stack using Trino, dbt, and Spark following the Medallion Architecture pattern with multi-engine processing.

## Architecture & Data Flow
- **Medallion Architecture**: Bronze (raw) → Silver (cleaned) → Gold (business) layers
- **Multi-Engine Pipeline**: CSV seeds → Bronze (dbt+Trino→Iceberg) → Silver (dbt+Spark→Iceberg) → Gold (dbt+PostgreSQL) → Metabase
- **Engine Selection**: Each layer optimized for specific workloads - Trino for OLAP/federation, Spark for heavy ETL, PostgreSQL for analytics
- **Storage Strategy**: Bronze/Silver use Iceberg tables on MinIO S3; Gold uses PostgreSQL for fast BI queries

✅ **Modernized Architecture**: Completely removed Hive Metastore dependency:
- **Iceberg REST Catalog**: Lightweight metadata management at port 8181
- **Pre-built Images**: `tabulario/spark-iceberg:3.5.1_1.4.3` eliminates complex builds  
- **Fast Startup**: Core services ready in ~2 minutes (vs 30+ previously)
- **Environment-driven Config**: All credentials via env vars, no hardcoded values

## Developer Workflow
- **Quick Start**: `make build && make up` (infrastructure), then `cd ecom_analytics && make run_all` (pipeline)
- **Service Dependencies**: PostgreSQL → MinIO → Iceberg REST → Trino (core services ~2min), then Spark cluster
- **Layer-specific Execution**: `make run_bronze` (Trino), `make run_silver` (Spark), `make run_gold` (PostgreSQL via Trino)
- **Data Management**: `make seed` (loads CSVs), `make test` (dbt tests), `make clean` (cleanup)
- **Monitoring**: `make status`, `make monitor_pipeline`, `make performance_report` for production-grade observability
- **Debugging**: Use `dbt run --models <model> --debug` and inspect `target/compiled/` for generated SQL
- **Profile Switching**: dbt automatically uses different profiles per layer via `--profile` flag in Makefile

## Key Conventions & Patterns
- **dbt Multi-Profile Architecture**: 
  - Bronze: `--profile trino` → Iceberg via Trino connector
  - Silver: `--profile spark` → Iceberg via Spark thrift server (port 10000)
  - Gold: `--profile gold` → PostgreSQL via Trino connector (`de_psql` catalog)
- **Layer-Specific Materializations**:
  - Bronze: `incremental` with `delete+insert`, partitioned by business key (e.g., `order_purchase_timestamp`)
  - Silver: `incremental` with `merge` strategy, clustered for query optimization
  - Gold: `table` materialization with PostgreSQL indexes for BI performance
- **Iceberg Configuration**: Pre-hooks in `dbt_project.yml` set S3A credentials for Spark layer
- **Testing Strategy**: 
  - Schema tests in `models/*/schema.yml` (not_null, unique, relationships, accepted_range)
  - Generic tests in `tests/generic/` for reusable business logic validation
  - Data quality gates via `dbt test` before layer transitions
- **Integration**:
  - MinIO/S3: S3-compatible storage at `s3a://warehouse/{bronze,silver,gold}` with env-driven credentials
  - Iceberg REST Catalog: Manages table metadata at `http://rest:8181` (replaces Hive Metastore entirely)
  - Trino: Federated queries across catalogs (`warehouse` for Iceberg, `de_psql` for PostgreSQL)
  - Spark: Heavy ETL via thrift server with pre-configured S3A settings in pre-hooks
  - Docker Health Checks: Service dependencies enforced via health checks (pg_isready, MinIO health endpoint, etc.)

## Infrastructure & Configuration
- **Docker Compose**: All services orchestrated; see `docker-compose.yml` and `docker/` for service configs
- **Environment Variables**: All credentials and endpoints managed via env vars; avoid hardcoding
- **Health Checks**: Service dependencies managed via health checks in compose

## Examples
- **Bronze Model**: `models/bronze/olist_orders.sql` (incremental, partitioned by `order_purchase_timestamp`, clustered by `customer_id`)
- **Silver Model**: `models/silver/fact_sales.sql` (complex joins, merge strategy, proportional payment calculations)
- **Gold Model**: `models/gold/sales_values_by_category.sql` (analytics aggregations, PostgreSQL indexes)
- **Testing**: `models/silver/schema.yml` (accepted_range tests, unique constraints, relationships)
- **Profile Example**: `profiles.yml.example` shows multi-profile setup (Trino/Spark/PostgreSQL)
- **Full Pipeline**:
  ```bash
  make build && make up  # Infrastructure (one-time setup)
  cd ecom_analytics && make run_all  # Complete data pipeline
  ```

## Tips for AI Agents
- Always reference engine-specific configs in `profiles.yml` and model configs in `dbt_project.yml`
- Use layer-specific patterns for incremental logic and partitioning
- Validate all new models with schema and generic tests
- Prefer environment variables for all credentials and endpoints
- Document new models and tests in `docs/` and `schema.yml`
- Use `make status` to check service health before troubleshooting
- Follow partition patterns: Bronze by `order_purchase_timestamp`, Silver by business keys, Gold as tables
- When debugging: check `target/compiled/` for generated SQL, use `--debug` flag for detailed logs

## Known Issues & Alternatives
- **Spark Build Issue**: Current Spark setup depends on slow Hive Metastore build
  - **Quick Alternative**: Use `tabulario/spark-iceberg` pre-built image
  - **Recommended Fix**: Replace Hive Metastore with Iceberg REST catalog
  - **Temporary Workaround**: Use Trino for all layers until Spark is optimized
- **dbt Environment**: UV/dbt setup may hang - use direct SQL for prototyping first
- **Service Startup**: Wait for health checks before running pipeline (`make up` includes health check waits)
- **Memory Requirements**: Ensure Docker has 8GB+ RAM allocated for full stack

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

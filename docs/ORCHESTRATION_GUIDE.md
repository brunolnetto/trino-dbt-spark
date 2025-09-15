# 📋 Pipeline Orchestration Guide

This guide covers the production-ready orchestration system built into the trino-dbt-spark project, featuring comprehensive monitoring, error handling, and operational capabilities.

## 🎯 Overview

The orchestration system provides:
- **Automated Error Handling**: Backup creation, cleanup on failures, rollback capabilities
- **Real-time Monitoring**: Pipeline execution tracking and performance metrics
- **Infrastructure Validation**: Health checks, dependency validation, and data quality gates
- **Comprehensive Logging**: Structured logging with execution IDs, timestamps, and audit trails
- **Performance Tracking**: Execution time analysis and resource usage monitoring

## 🚀 Quick Start Commands

### Core Pipeline Operations

```bash
# Execute complete medallion pipeline with monitoring
make run_all

# Execute specific layers
make run_bronze    # Raw data ingestion (Trino + Iceberg)
make run_silver    # Data transformations (Spark + Iceberg)  
make run_gold      # Analytics models (PostgreSQL)

# Load initial seed data
make seed
```

### Monitoring & Status

```bash
# Real-time pipeline monitoring (Ctrl+C to exit)
make monitor_pipeline

# Check current pipeline status and health
make status

# Generate detailed performance report
make performance_report
```

### Recovery Operations

```bash
# Rollback specific layer on failures
make rollback_layer LAYER=bronze
make rollback_layer LAYER=silver
make rollback_layer LAYER=gold

# Clean up old logs and backups
make cleanup_logs
```

## 🔍 Monitoring System

### Real-time Pipeline Monitor

The `make monitor_pipeline` command provides a live dashboard showing:

```
🔄 Pipeline Monitor - Sat Sep 14 21:15:32 UTC 2025
=====================================
📋 Recent Activity:
[2025-09-14 21:14:45] ✅ Bronze layer completed successfully
[2025-09-14 21:14:50] 🚀 Starting silver layer execution...
[2025-09-14 21:15:20] 📊 Processing fact_sales model
[2025-09-14 21:15:25] 📊 Processing dim_products model

📊 Container Status:
NAME           STATUS          PORTS
trino          Up 45 minutes   0.0.0.0:8081->8080/tcp
spark-master   Up 45 minutes   0.0.0.0:7077->7077/tcp
```

### Status Dashboard

The `make status` command provides comprehensive system information:

```bash
📊 Pipeline Status Report
========================
🕐 Current time: Sat Sep 14 21:15:32 UTC 2025
🆔 Last execution: pipeline_20250914_211530_12345.log

🐳 Infrastructure Status:
[Container health status table]

📁 Recent Logs:
[Last 10 log entries]

💾 Available Backups:
[Recent backup files]
```

## 📊 Performance Tracking

### Execution Metrics

Each pipeline run automatically tracks:

- **Execution Times**: Per-layer and per-model timing
- **Resource Usage**: Memory, disk space, and CPU load
- **Data Volume**: Records processed, table sizes
- **Error Rates**: Failed models, retry counts

### Performance Report

The `make performance_report` generates detailed metrics:

```
⚡ Performance Report for Execution: 20250914_211530_12345
=================================
📊 Execution Times:
Bronze layer completed successfully in 45.2 seconds
Silver layer completed successfully in 127.8 seconds  
Gold layer completed successfully in 23.1 seconds

📈 Resource Usage:
Memory: 6.2G/16G
Disk: 45G/100G (45% used)
Load: 1.25, 1.30, 1.45
```

## 🛡️ Error Handling & Recovery

### Automatic Backup System

Before each layer execution, the system automatically:

1. **Creates snapshots** of existing data
2. **Validates dependencies** (services, schemas, data quality)
3. **Logs backup locations** for recovery

```bash
💾 Creating backup for layer silver...
✅ Backup created: backups/silver_backup_20250914_211530.sql
```

### Rollback Procedures

When failures occur, use targeted rollback:

```bash
# Rollback a specific layer
make rollback_layer LAYER=silver

# This will:
# 1. Stop current execution
# 2. Restore from most recent backup
# 3. Validate data integrity  
# 4. Update execution logs
```

### Failure Recovery Workflow

1. **Identify the issue** using logs and monitoring
2. **Assess impact** - which layer/models failed
3. **Rollback if needed** to stable state
4. **Fix root cause** (data, configuration, resources)
5. **Resume execution** from failed point

## 📋 Logging System

### Log Structure

Each execution generates structured logs with:

```
[TIMESTAMP] [LEVEL] [COMPONENT] MESSAGE
[2025-09-14 21:15:30] INFO  [ORCHESTRATOR] 🚀 Starting silver layer execution...
[2025-09-14 21:15:32] INFO  [DBT] Building model fact_sales
[2025-09-14 21:15:45] WARN  [SPARK] Slow query detected (>30s)
[2025-09-14 21:15:50] INFO  [ORCHESTRATOR] ✅ Silver layer completed successfully
```

### Log Locations

- **Pipeline Logs**: `logs/pipeline/pipeline_[EXECUTION_ID].log`
- **Performance Reports**: `reports/performance_[EXECUTION_ID].json`
- **Backup Metadata**: `backups/backup_[LAYER]_[TIMESTAMP].sql`

### Log Retention

- **Pipeline logs**: 30 days
- **Performance reports**: 30 days  
- **Backup files**: 7 days
- **Error logs**: Indefinite (manual cleanup)

## 🔧 Configuration Options

### Environment Variables

Key orchestration settings in `.env`:

```bash
# Pipeline settings
PIPELINE_LOG_DIR=logs/pipeline
PIPELINE_BACKUP_DIR=backups
PIPELINE_REPORTS_DIR=reports

# Performance tuning
DBT_THREADS=4
SPARK_WORKER_MEMORY=2G
TRINO_MEMORY_LIMIT=8G
```

### Execution Parameters

Customize pipeline behavior:

```bash
# Disable full refresh for incremental runs
make run_all FULL_REFRESH=

# Specify custom execution ID
make run_all EXECUTION_ID=custom_run_001

# Run with enhanced logging
make run_all VERBOSE=true
```

## 🏥 Health Checks & Validation

### Infrastructure Validation

Before each run, the system validates:

- **Service Health**: All containers running and responsive
- **Database Connectivity**: Trino, Spark, PostgreSQL connections
- **Storage Access**: MinIO/S3 bucket permissions
- **Catalog Availability**: Iceberg REST catalog functionality

### Data Quality Gates

Automatic validation includes:

- **Schema Compatibility**: Source data structure validation
- **Data Freshness**: Timestamp and freshness checks
- **Record Counts**: Expected volume validation
- **Business Rules**: Custom data quality tests

### Dependency Checks

The orchestrator verifies:

- **Source Tables**: Required tables exist and accessible
- **Schema Compatibility**: Column types and constraints
- **Resource Availability**: Sufficient memory and disk space
- **Service Dependencies**: All required services healthy

## 🎛️ Advanced Operations

### Parallel Execution

For improved performance:

```bash
# Run multiple layers in parallel (where dependencies allow)
make run_bronze & make run_external &

# Monitor parallel execution
make monitor_pipeline
```

### Custom Layer Execution

Execute specific model subsets:

```bash
# Run only specific models in silver layer
cd ecom_analytics
dbt run --select fact_sales --profile spark

# Run models with specific tags
dbt run --select tag:core --profile spark
```

### Integration with CI/CD

Example GitHub Actions integration:

```yaml
- name: Run Data Pipeline
  run: |
    make validate_infrastructure
    make run_all FULL_REFRESH=
    make test
    make performance_report
```

## 🚨 Troubleshooting

### Common Issues

1. **Service Startup Failures**
   ```bash
   make status  # Check service health
   docker-compose logs [service_name]
   ```

2. **Memory/Resource Issues**
   ```bash
   make performance_report  # Check resource usage
   # Reduce parallelism or increase limits
   ```

3. **Data Quality Failures**
   ```bash
   make test  # Run comprehensive test suite
   # Check logs for specific failures
   ```

4. **Connectivity Problems**
   ```bash
   make validate_dependencies  # Test all connections
   # Verify network and credentials
   ```

### Debug Mode

Enable detailed debugging:

```bash
# Run with maximum verbosity
make run_all VERBOSE=true DEBUG=true

# Check specific component logs
docker-compose logs -f trino
docker-compose logs -f spark-master
```

## 📚 Best Practices

### Operational Excellence

1. **Monitor Regularly**: Use `make monitor_pipeline` during development
2. **Test Incrementally**: Run `make test` after significant changes
3. **Backup Before Changes**: Always create manual backups for major updates
4. **Review Performance**: Weekly `make performance_report` analysis
5. **Clean Regularly**: Monthly `make cleanup_logs` execution

### Development Workflow

1. **Start with Bronze**: Test data ingestion first
2. **Validate Each Layer**: Run tests between layer executions
3. **Monitor Resource Usage**: Watch for memory/disk issues
4. **Use Incremental Builds**: Disable `FULL_REFRESH` for faster iteration
5. **Document Changes**: Update this guide for new features

### Production Deployment

1. **Health Checks**: Comprehensive validation before deployment
2. **Gradual Rollout**: Layer-by-layer deployment with validation
3. **Monitoring**: 24/7 monitoring with alerting
4. **Backup Strategy**: Automated daily backups with retention policy
5. **Recovery Procedures**: Documented and tested rollback procedures

---

## 📞 Support

For orchestration issues:

1. **Check Logs**: Start with `make status` and recent log files
2. **Validate Health**: Run `make validate_infrastructure`
3. **Performance Issues**: Generate `make performance_report`
4. **Recovery**: Use appropriate `make rollback_layer` commands

Remember: The orchestration system is designed for reliability and observability. When in doubt, check the logs and use the monitoring tools provided.
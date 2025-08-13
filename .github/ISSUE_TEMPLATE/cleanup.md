---
name: Infrastructure Cleanup
about: Track infrastructure refactoring and cleanup tasks
title: 'refactor: Infrastructure cleanup and security improvements'
labels: refactor, infrastructure
---

# Infrastructure Cleanup Plan

## 1. PostgreSQL Migration Completion

- [ ] Update Hive Metastore JDBC driver configuration:
  ```xml
  <!-- in docker/hive-metastore/conf/hive-site.xml -->
  <property>
    <n>javax.jdo.option.ConnectionDriverName</n>
    <value>org.postgresql.Driver</value>
  </property>
  ```
- [ ] Remove MySQL directory:
  ```bash
  rm -rf docker/mysql/
  ```
- [ ] Remove MySQL connector from Spark Dockerfile:
  ```dockerfile
  # Remove from docker/spark/Dockerfile
  - mysql-connector-java-8.0.19.jar
  ```

## 2. Credentials Management

- [ ] Create `.env.template` file with required variables:
  ```env
  # MinIO/S3 Configuration
  MINIO_ACCESS_KEY=changeme
  MINIO_SECRET_KEY=changeme
  MINIO_URL=http://minio:9000

  # PostgreSQL Configuration
  POSTGRES_USER=changeme
  POSTGRES_PASSWORD=changeme
  POSTGRES_DB=metastore_db

  # Hive Metastore
  HIVE_METASTORE_USER=changeme
  HIVE_METASTORE_PASSWORD=changeme
  ```

  - [ ] Update service configurations to use environment variables:
  - [ ] docker/hive-metastore/conf/hive-site.xml
  - [ ] docker/trino/catalog/warehouse.properties
  - [ ] docker/spark/conf/spark-defaults.conf

## 3. Template Files Cleanup

Remove unused template files or implement them properly:
- [ ] Review and implement or remove:

  ```bash
  docker/spark/conf/
  ├── fairscheduler.xml.template
  ├── log4j2.properties.template
  ├── metrics.properties.template
  ├── spark-defaults.conf.template
  ├── spark-env.sh.template
  └── workers.template
  ```

## 4. Docker Configuration Updates

- [ ] Update docker-compose.yml to use environment variables
- [ ] Add proper health checks for services
- [ ] Implement proper volume management
- [ ] Add logging configuration

## 5. Documentation Updates

- [ ] Update README with environment setup instructions
- [ ] Document service configuration patterns
- [ ] Add troubleshooting guide
- [ ] Update architecture diagrams

## Implementation Steps

### Phase 1: Environment Configuration

1. Create `.env.template`
2. Update docker-compose.yml
3. Test with new environment variables

### Phase 2: PostgreSQL Migration

1. Update Hive Metastore configuration
2. Remove MySQL artifacts
3. Test Hive Metastore connectivity

### Phase 3: Template Cleanup

1. Review each template file
2. Implement or remove templates
3. Update documentation

### Phase 4: Security Improvements
1. Implement proper secrets management
2. Update service configurations
3. Test connectivity with new configuration

## Testing Plan

1. Start fresh environment with new configuration
2. Verify all services start correctly
3. Run end-to-end pipeline test
4. Verify data access and permissions

## Rollback Plan
1. Keep backup of original configurations
2. Document current working state
3. Test rollback procedure

## Additional Notes

- Take database backups before changes
- Schedule maintenance window
- Update team about changes

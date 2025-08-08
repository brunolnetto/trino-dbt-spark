# Run Bronze layer with Trino profile
run_bronze:
	dbt run --profiles-dir ./ --profile trino --select bronze --full-refresh

# Run Silver layer with Spark profile
run_silver:
	dbt run --profiles-dir ./ --profile spark --select silver --full-refresh

# Run Gold layer with Trino (Postgres catalog) profile
run_gold:
	dbt run --profiles-dir ./ --profile gold --select gold --full-refresh

# Full pipeline: Bronze -> seed -> external sources -> Silver -> Gold
run_all:
	make run_bronze && make seed && make run_external && make run_silver && make run_gold

# Run any external staging macros for Spark
run_external:
	dbt run-operation --profiles-dir ./ --profile spark stage_external_sources

# Install dependencies (one project now)
install_deps:
	dbt deps

# Seed data into Bronze layer
seed:
	dbt seed --profiles-dir ./ --profile trino --full-refresh
	
# Generate docs (pick one profile for docs, here using Spark)
docs:
	dbt docs generate --profiles-dir ./ --profile spark

# Run a specific script/model for Spark
select:
	dbt run --profiles-dir ./ --profile spark --select $(script)

# Run tests for Spark models
test:
	dbt test --profiles-dir ./ --profile spark

# Include env file (API keys, DB creds, etc.)
include .env

# Docker compose helper
DOCKER_COMPOSE := docker-compose --env-file .env

# dbt settings (adjust if needed)
DBT_PROJECT_DIR := ecom_analytics
DBT_PROFILES_DIR := .
DBT_PROFILE_BRONZE := trino
DBT_PROFILE_SILVER := spark
DBT_PROFILE_GOLD := gold

SELECT_BRONZE := bronze
SELECT_SILVER := silver
SELECT_GOLD := gold

# Allow overriding to avoid full-refresh on CI or dev
# Usage:
#   make run_all            -> uses default: --full-refresh
#   make run_all FULL_REFRESH=    -> disables full-refresh (incremental mode)
FULL_REFRESH ?= --full-refresh


.PHONY: build up down restart \
	to_psql \
	run_bronze run_external run_silver run_gold run_all \
	seed install_deps docs select test lint find

lint-fix:
	sqlfluff fix --dialect trino ecom_analytics/models/**/*.sql

# Find files in the project
# Usage:
#   make find PATTERN=some_model     -> Find files containing "some_model"
#   make find PATTERN=model DIR=silver -> Find files containing "model" in silver directory
find:
	@if [ -z "$(PATTERN)" ]; then \
		echo "Error: PATTERN is required. Usage: make find PATTERN=search_term [DIR=directory]"; \
		exit 1; \
	fi; \
	if [ -z "$(DIR)" ]; then \
		echo "Searching for '$(PATTERN)' in all project files:"; \
		grep -r --include="*.sql" --include="*.yml" --include="*.md" "$(PATTERN)" $(DBT_PROJECT_DIR); \
	else \
		echo "Searching for '$(PATTERN)' in $(DBT_PROJECT_DIR)/$(DIR):"; \
		grep -r --include="*.sql" --include="*.yml" --include="*.md" "$(PATTERN)" $(DBT_PROJECT_DIR)/$(DIR); \
	fi

# Docker helpers
build:
	$(DOCKER_COMPOSE) build

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

restart: down up

to_psql:
	docker exec -ti de_psql psql postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# --------------------------------------
# dbt orchestration (single project)
# --------------------------------------

# 1) Bronze: run Bronze models with Trino profile (writes Iceberg to S3/MinIO)
run_bronze:
	dbt build --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) --select $(SELECT_BRONZE) $(FULL_REFRESH)

# 2) Silver: run Silver models with Spark profile (reads Bronze Iceberg -> writes Silver Iceberg)
run_silver:
	dbt build --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) --select $(SELECT_SILVER) $(FULL_REFRESH)

# Run any external data processing steps (if needed)
run_external:
	@echo "Running external data processing steps..."
	# Add your external data processing commands here if needed
	# If not needed, this is just a placeholder for the run_all target

# 3) Gold: run Gold models (Trino profile pointed at Postgres catalog)
run_gold:
	dbt build --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_GOLD) --select $(SELECT_GOLD) $(FULL_REFRESH)

# Seed CSVs into Bronze layer (profile=trino so seeds land where Bronze expects them)
seed:
	dbt seed --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) $(FULL_REFRESH)

# Combined pipeline (keeps same order as before)
# NOTE: can override FULL_REFRESH empty in CI for incremental runs:
#   make run_all FULL_REFRESH=""
run_all: seed run_bronze run_external run_silver run_gold

# doc generation (use spark or whichever profile can see your sources)
docs:
	dbt docs generate --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER)

deps:
	dbt deps --project-dir $(DBT_PROJECT_DIR)

# Run a selected model/script against Spark
select:
	dbt run --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) --select $(script)

test:
	dbt test --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER)

# List database objects
# Usage:
#   make list_objects PROFILE=spark    -> List objects in Spark
#   make list_objects PROFILE=trino    -> List objects in Trino
list_objects:
	@PROFILE=$${PROFILE:-$(DBT_PROFILE_SILVER)}; \
	echo "Listing database objects for profile: $$PROFILE"; \
	dbt ls --resource-type model --output name --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $$PROFILE

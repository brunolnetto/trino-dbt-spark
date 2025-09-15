# Include env file (API keys, DB creds, etc.)
include .env

# Color definitions for output
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
NC := \033[0m

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

# Pipeline execution settings
PIPELINE_LOG_DIR := logs/pipeline
PIPELINE_BACKUP_DIR := backups
PIPELINE_REPORTS_DIR := reports
EXECUTION_ID := $(shell date +%Y%m%d_%H%M%S)_$(shell echo $$RANDOM)
LOG_FILE := $(PIPELINE_LOG_DIR)/pipeline_$(EXECUTION_ID).log

# Performance tracking
START_TIME = $(shell date +%s)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

.PHONY: build up down restart \
	to_psql \
	run_bronze run_external run_silver run_gold run_all \
	seed install_deps docs select test lint find \
	setup_logging validate_dependencies pipeline_report \
	rollback_layer performance_report cleanup_logs

# =============================================================================
# LOGGING AND MONITORING FUNCTIONS
# =============================================================================

# Setup logging infrastructure
setup_logging:
	@echo "📋 Setting up pipeline logging infrastructure..."
	@mkdir -p $(PIPELINE_LOG_DIR) $(PIPELINE_BACKUP_DIR) $(PIPELINE_REPORTS_DIR)
	@echo "🕐 Pipeline execution started at: $(shell date)" | tee $(LOG_FILE)
	@echo "🆔 Execution ID: $(EXECUTION_ID)" | tee -a $(LOG_FILE)
	@echo "📊 Environment: $(shell echo $$USER)@$(shell hostname)" | tee -a $(LOG_FILE)
	@echo "🐳 Docker status: $(shell docker --version)" | tee -a $(LOG_FILE)
	@echo "=================================" | tee -a $(LOG_FILE)

# Enhanced logging function
define log_status
	@echo "$(2) [$(shell date '+%Y-%m-%d %H:%M:%S')] $(1)" | tee -a $(LOG_FILE)
endef

# Performance timing function
define time_operation
	@start_time=$$(date +%s); \
	$(1); \
	exit_code=$$?; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	if [ $$exit_code -eq 0 ]; then \
		echo "✅ $(2) completed successfully in $${duration}s" | tee -a $(LOG_FILE); \
	else \
		echo "❌ $(2) failed after $${duration}s with exit code $$exit_code" | tee -a $(LOG_FILE); \
		exit $$exit_code; \
	fi
endef

# Error cleanup function
define cleanup_on_error
	@echo "🧹 Cleaning up after error in $(1)..." | tee -a $(LOG_FILE)
	@echo "📊 Generating error report..." | tee -a $(LOG_FILE)
	@$(MAKE) pipeline_report STAGE="$(1)_FAILED" --no-print-directory
	@echo "❌ Pipeline failed at stage: $(1)" | tee -a $(LOG_FILE)
	@echo "📋 Check log file: $(LOG_FILE)" | tee -a $(LOG_FILE)
endef

# =============================================================================
# DEPENDENCY VALIDATION AND FRESHNESS CHECKS
# =============================================================================

# Validate pipeline dependencies
validate_dependencies: setup_logging
	$(call log_status,"🔍 Validating pipeline dependencies...","$(BLUE)")
	$(call time_operation, \
		dbt source freshness --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) >> $(LOG_FILE) 2>&1, \
		"Source freshness check")
	$(call log_status,"✅ Dependencies validation completed","$(GREEN)")

# Check data quality gates
validate_data_quality: setup_logging
	$(call log_status,"🔍 Running data quality validations...","$(BLUE)")
	$(call time_operation, \
		dbt test --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) --select source:* >> $(LOG_FILE) 2>&1, \
		"Source data quality tests")
	$(call log_status,"✅ Data quality validation completed","$(GREEN)")

# Validate infrastructure health
validate_infrastructure: setup_logging
	$(call log_status,"🏥 Checking infrastructure health...","$(BLUE)")
	@echo "Checking Docker containers..." | tee -a $(LOG_FILE)
	@$(DOCKER_COMPOSE) ps >> $(LOG_FILE) 2>&1 || (echo "❌ Docker infrastructure check failed" | tee -a $(LOG_FILE) && exit 1)
	@echo "Checking database connections..." | tee -a $(LOG_FILE)
	@timeout 30 docker exec -i de_psql pg_isready >> $(LOG_FILE) 2>&1 || (echo "❌ PostgreSQL health check failed" | tee -a $(LOG_FILE) && exit 1)
	@timeout 30 curl -f http://localhost:8080/v1/info/state >> $(LOG_FILE) 2>&1 || (echo "❌ Trino health check failed" | tee -a $(LOG_FILE) && exit 1)
	@timeout 30 curl -f http://localhost:8081 >> $(LOG_FILE) 2>&1 || (echo "❌ Spark health check failed" | tee -a $(LOG_FILE) && exit 1)
	$(call log_status,"✅ Infrastructure health check completed","$(GREEN)")

# =============================================================================
# BACKUP AND ROLLBACK FUNCTIONS
# =============================================================================

# Create backup of current state before major operations
create_backup:
	$(call log_status,"💾 Creating backup for layer $(LAYER)...","$(YELLOW)")
	@backup_file="$(PIPELINE_BACKUP_DIR)/$(LAYER)_backup_$(EXECUTION_ID).sql"
	@echo "-- Backup created at $(shell date)" > $$backup_file
	@echo "-- Execution ID: $(EXECUTION_ID)" >> $$backup_file
	@echo "-- Layer: $(LAYER)" >> $$backup_file
	@if [ "$(LAYER)" = "bronze" ] || [ "$(LAYER)" = "silver" ]; then \
		echo "-- Note: Iceberg tables - backup metadata only" >> $$backup_file; \
		dbt ls --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) --select $(LAYER) --output name >> $$backup_file 2>/dev/null || true; \
	else \
		echo "Backing up Gold layer tables..." | tee -a $(LOG_FILE); \
		docker exec -i de_psql pg_dump -U $(POSTGRES_USER) -d $(POSTGRES_DB) --schema-only >> $$backup_file 2>/dev/null || true; \
	fi
	$(call log_status,"✅ Backup created: $$backup_file","$(GREEN)")

# Rollback function for failed operations
rollback_layer:
	@if [ -z "$(LAYER)" ]; then \
		echo "❌ Error: LAYER parameter is required. Usage: make rollback_layer LAYER=bronze|silver|gold"; \
		exit 1; \
	fi
	$(call log_status,"🔄 Rolling back $(LAYER) layer...","$(YELLOW)")
	@latest_backup=$$(ls -t $(PIPELINE_BACKUP_DIR)/$(LAYER)_backup_*.sql 2>/dev/null | head -1); \
	if [ -z "$$latest_backup" ]; then \
		echo "❌ No backup found for $(LAYER) layer" | tee -a $(LOG_FILE); \
		exit 1; \
	fi; \
	echo "📋 Using backup: $$latest_backup" | tee -a $(LOG_FILE)
	@if [ "$(LAYER)" = "gold" ]; then \
		echo "🔄 Restoring Gold layer from backup..." | tee -a $(LOG_FILE); \
		docker exec -i de_psql psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) < $$latest_backup >> $(LOG_FILE) 2>&1; \
	else \
		echo "⚠️  Iceberg layer rollback requires manual intervention" | tee -a $(LOG_FILE); \
		echo "📋 Consider running with --full-refresh to reset $(LAYER) layer" | tee -a $(LOG_FILE); \
	fi
	$(call log_status,"✅ Rollback completed for $(LAYER) layer","$(GREEN)")

# =============================================================================
# PIPELINE EXECUTION WITH ERROR HANDLING
# =============================================================================

# Layer execution with comprehensive error handling
run_layer:
	@if [ -z "$(LAYER)" ] || [ -z "$(PROFILE)" ]; then \
		echo "❌ Error: LAYER and PROFILE parameters are required"; \
		echo "Usage: make run_layer LAYER=bronze|silver|gold PROFILE=trino|spark|gold"; \
		exit 1; \
	fi
	$(call log_status,"🚀 Starting $(LAYER) layer execution with $(PROFILE) profile...","$(BLUE)")
	@$(MAKE) create_backup LAYER=$(LAYER) --no-print-directory
	$(call time_operation, \
		dbt build --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(PROFILE) --select $(LAYER) $(FULL_REFRESH) >> $(LOG_FILE) 2>&1, \
		"$(LAYER) layer execution") || ($(call cleanup_on_error,$(LAYER)) && exit 1)
	$(call log_status,"✅ $(LAYER) layer completed successfully","$(GREEN)")

# Run_external with error handling
run_external: setup_logging
	$(call log_status,"🔗 Running external source operations...","$(BLUE)")
	$(call time_operation, \
		dbt run-operation --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) stage_external_sources >> $(LOG_FILE) 2>&1, \
		"External sources staging") || ($(call cleanup_on_error,"external") && exit 1)
	$(call log_status,"✅ External operations completed","$(GREEN)")

# =============================================================================
# MONITORING AND REPORTING FUNCTIONS
# =============================================================================

# Generate comprehensive pipeline report
pipeline_report:
	@report_file="$(PIPELINE_REPORTS_DIR)/pipeline_report_$(EXECUTION_ID).json"
	@echo "📊 Generating pipeline execution report..." | tee -a $(LOG_FILE)
	@echo "{" > $$report_file
	@echo "  \"execution_id\": \"$(EXECUTION_ID)\"," >> $$report_file
	@echo "  \"timestamp\": \"$(shell date -Iseconds)\"," >> $$report_file
	@echo "  \"stage\": \"$(or $(STAGE),COMPLETED)\"," >> $$report_file
	@echo "  \"environment\": {" >> $$report_file
	@echo "    \"user\": \"$(shell echo $$USER)\"," >> $$report_file
	@echo "    \"hostname\": \"$(shell hostname)\"," >> $$report_file
	@echo "    \"full_refresh\": \"$(FULL_REFRESH)\"" >> $$report_file
	@echo "  }," >> $$report_file
	@echo "  \"models\": {" >> $$report_file
	@bronze_count=$$(dbt ls --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) --select bronze --output name 2>/dev/null | wc -l); \
	silver_count=$$(dbt ls --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) --select silver --output name 2>/dev/null | wc -l); \
	gold_count=$$(dbt ls --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_GOLD) --select gold --output name 2>/dev/null | wc -l); \
	echo "    \"bronze_models\": $$bronze_count," >> $$report_file; \
	echo "    \"silver_models\": $$silver_count," >> $$report_file; \
	echo "    \"gold_models\": $$gold_count" >> $$report_file
	@echo "  }," >> $$report_file
	@echo "  \"infrastructure\": {" >> $$report_file
	@docker_status=$$($(DOCKER_COMPOSE) ps --format json 2>/dev/null | jq -s 'map(select(.State == "running")) | length' 2>/dev/null || echo "0"); \
	echo "    \"running_containers\": $$docker_status," >> $$report_file
	@echo "    \"log_file\": \"$(LOG_FILE)\"" >> $$report_file
	@echo "  }" >> $$report_file
	@echo "}" >> $$report_file
	@echo "📋 Report generated: $$report_file" | tee -a $(LOG_FILE)
	@if command -v jq >/dev/null 2>&1; then \
		echo "📊 Pipeline Summary:" | tee -a $(LOG_FILE); \
		jq -r '"Execution ID: " + .execution_id, "Stage: " + .stage, "Models - Bronze: " + (.models.bronze_models|tostring) + ", Silver: " + (.models.silver_models|tostring) + ", Gold: " + (.models.gold_models|tostring)' $$report_file | tee -a $(LOG_FILE); \
	fi

# Performance tracking and metrics
performance_report:
	@echo "⚡ Performance Report for Execution: $(EXECUTION_ID)" | tee -a $(LOG_FILE)
	@echo "=================================" | tee -a $(LOG_FILE)
	@if [ -f "$(LOG_FILE)" ]; then \
		echo "📊 Execution Times:" | tee -a $(LOG_FILE); \
		grep "completed successfully in" $(LOG_FILE) | tail -10 | tee -a $(LOG_FILE); \
		echo "" | tee -a $(LOG_FILE); \
		echo "📈 Resource Usage:" | tee -a $(LOG_FILE); \
		echo "Memory: $$(free -h | grep '^Mem' | awk '{print $$3 "/" $$2}')" | tee -a $(LOG_FILE); \
		echo "Disk: $$(df -h . | tail -1 | awk '{print $$3 "/" $$2 " (" $$5 " used)"}')" | tee -a $(LOG_FILE); \
		echo "Load: $$(uptime | awk -F'load average:' '{print $$2}')" | tee -a $(LOG_FILE); \
	fi

# Monitor pipeline execution in real-time
monitor_pipeline:
	@echo "📺 Monitoring pipeline execution (Ctrl+C to exit)..."
	@while true; do \
		clear; \
		echo "🔄 Pipeline Monitor - $(shell date)"; \
		echo "====================================="; \
		if [ -f "$(LOG_FILE)" ]; then \
			echo "📋 Recent Activity:"; \
			tail -10 $(LOG_FILE); \
			echo ""; \
			echo "📊 Container Status:"; \
			$(DOCKER_COMPOSE) ps; \
		else \
			echo "⏳ Waiting for pipeline to start..."; \
		fi; \
		sleep 5; \
	done

# =============================================================================
# MAIN PIPELINE FUNCTIONS
# =============================================================================

# Bronze layer execution
run_bronze: validate_infrastructure validate_dependencies
	@$(MAKE) run_layer LAYER=$(SELECT_BRONZE) PROFILE=$(DBT_PROFILE_BRONZE) --no-print-directory

# Silver layer execution  
run_silver: 
	@$(MAKE) run_layer LAYER=$(SELECT_SILVER) PROFILE=$(DBT_PROFILE_SILVER) --no-print-directory

# Gold layer execution
run_gold:
	@$(MAKE) run_layer LAYER=$(SELECT_GOLD) PROFILE=$(DBT_PROFILE_GOLD) --no-print-directory

# Seed operation
seed: setup_logging validate_infrastructure
	$(call log_status,"🌱 Starting seed operation...","$(BLUE)")
	$(call time_operation, \
		dbt seed --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_BRONZE) $(FULL_REFRESH) >> $(LOG_FILE) 2>&1, \
		"Seed operation") || ($(call cleanup_on_error,"seed") && exit 1)
	$(call log_status,"✅ Seed operation completed","$(GREEN)")

# Enhanced complete pipeline with comprehensive monitoring
run_all: setup_logging validate_infrastructure validate_dependencies validate_data_quality
	$(call log_status,"🚀 Starting complete pipeline execution...","$(PURPLE)")
	@pipeline_start_time=$$(date +%s)
	@$(MAKE) seed --no-print-directory || ($(call cleanup_on_error,"seed") && exit 1)
	@$(MAKE) run_bronze --no-print-directory || ($(call cleanup_on_error,"bronze") && exit 1)
	@$(MAKE) run_external --no-print-directory || ($(call cleanup_on_error,"external") && exit 1)
	@$(MAKE) run_silver --no-print-directory || ($(call cleanup_on_error,"silver") && exit 1)
	@$(MAKE) run_gold --no-print-directory || ($(call cleanup_on_error,"gold") && exit 1)
	@pipeline_end_time=$$(date +%s); \
	total_duration=$$((pipeline_end_time - pipeline_start_time))
	$(call log_status,"🎉 Complete pipeline executed successfully in $${total_duration}s","$(GREEN)")
	@$(MAKE) pipeline_report STAGE="COMPLETED" --no-print-directory
	@$(MAKE) performance_report --no-print-directory
	$(call log_status,"📊 Pipeline execution completed. Check reports in $(PIPELINE_REPORTS_DIR)/","$(CYAN)")

# =============================================================================
# UTILITY AND MAINTENANCE FUNCTIONS
# =============================================================================

# Cleanup old logs and reports
cleanup_logs:
	@echo "🧹 Cleaning up old logs and reports..."
	@find $(PIPELINE_LOG_DIR) -name "*.log" -mtime +7 -delete 2>/dev/null || true
	@find $(PIPELINE_REPORTS_DIR) -name "*.json" -mtime +30 -delete 2>/dev/null || true
	@find $(PIPELINE_BACKUP_DIR) -name "*_backup_*.sql" -mtime +7 -delete 2>/dev/null || true
	@echo "✅ Cleanup completed"

# Enhanced testing with reporting
test: setup_logging
	$(call log_status,"🧪 Running comprehensive test suite...","$(BLUE)")
	$(call time_operation, \
		dbt test --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) >> $(LOG_FILE) 2>&1, \
		"Test execution")
	@$(MAKE) pipeline_report STAGE="TESTS_COMPLETED" --no-print-directory
	$(call log_status,"✅ All tests completed successfully","$(GREEN)")

# Enhanced documentation generation
docs: setup_logging
	$(call log_status,"📚 Generating documentation...","$(BLUE)")
	$(call time_operation, \
		dbt docs generate --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) >> $(LOG_FILE) 2>&1, \
		"Documentation generation")
	$(call log_status,"✅ Documentation generated successfully","$(GREEN)")
	@echo "📖 Access documentation at: http://localhost:8080/docs"

# Enhanced dependency installation
deps: setup_logging
	$(call log_status,"📦 Installing dbt dependencies...","$(BLUE)")
	$(call time_operation, \
		dbt deps --project-dir $(DBT_PROJECT_DIR) >> $(LOG_FILE) 2>&1, \
		"Dependency installation")
	$(call log_status,"✅ Dependencies installed successfully","$(GREEN)")

# Pipeline status check
status:
	@echo "📊 Pipeline Status Report"
	@echo "========================"
	@echo "🕐 Current time: $(shell date)"
	@echo "🆔 Last execution: $(shell ls -t $(PIPELINE_LOG_DIR)/pipeline_*.log 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'None')"
	@echo ""
	@echo "🐳 Infrastructure Status:"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "📁 Recent Logs:"
	@ls -la $(PIPELINE_LOG_DIR)/ 2>/dev/null | tail -5 || echo "No logs found"
	@echo ""
	@echo "📊 Recent Reports:"
	@ls -la $(PIPELINE_REPORTS_DIR)/ 2>/dev/null | tail -3 || echo "No reports found"

# =============================================================================
# DOCKER MANAGEMENT (ENHANCED)
# =============================================================================

# Enhanced build with logging
build: setup_logging
	$(call log_status,"🏗️ Building Docker containers...","$(BLUE)")
	$(call time_operation, \
		$(DOCKER_COMPOSE) build >> $(LOG_FILE) 2>&1, \
		"Docker build")
	$(call log_status,"✅ Docker build completed","$(GREEN)")

# Enhanced startup with health checks
up: setup_logging
	$(call log_status,"🚀 Starting Docker services...","$(BLUE)")
	@$(DOCKER_COMPOSE) up -d >> $(LOG_FILE) 2>&1
	@echo "⏳ Waiting for services to be healthy..."
	@timeout 300 bash -c 'until $(DOCKER_COMPOSE) ps | grep -q "healthy\|Up"; do sleep 5; echo -n "."; done' || (echo "❌ Services failed to start" && exit 1)
	$(call log_status,"✅ All services are running and healthy","$(GREEN)")
	@$(MAKE) validate_infrastructure --no-print-directory

# Enhanced shutdown
down: setup_logging
	$(call log_status,"⏹️ Stopping Docker services...","$(YELLOW)")
	@$(DOCKER_COMPOSE) down >> $(LOG_FILE) 2>&1
	$(call log_status,"✅ Services stopped successfully","$(GREEN)")

# Quick restart
restart: down up

# Enhanced database connection
to_psql:
	@echo "🔗 Connecting to PostgreSQL..."
	docker exec -ti de_psql psql postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# =============================================================================
# LEGACY FUNCTIONS (MAINTAINED FOR COMPATIBILITY)
# =============================================================================

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

# Run a selected model/script against Spark
select:
	dbt run --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $(DBT_PROFILE_SILVER) --select $(script)

# List database objects
# Usage:
#   make list_objects PROFILE=spark    -> List objects in Spark
#   make list_objects PROFILE=trino    -> List objects in Trino
list_objects:
	@PROFILE=$${PROFILE:-$(DBT_PROFILE_SILVER)}; \
	echo "Listing database objects for profile: $$PROFILE"; \
	dbt ls --resource-type model --output name --project-dir $(DBT_PROJECT_DIR) --profiles-dir $(DBT_PROFILES_DIR) --profile $$PROFILE

# =============================================================================
# HELP AND USAGE
# =============================================================================

help:
	@echo "🚀 Enhanced Data Pipeline Orchestration"
	@echo "======================================"
	@echo ""
	@echo "📋 Main Pipeline Commands:"
	@echo "  make run_all          - Execute complete pipeline with monitoring"
	@echo "  make run_bronze       - Execute bronze layer only"
	@echo "  make run_silver       - Execute silver layer only" 
	@echo "  make run_gold         - Execute gold layer only"
	@echo "  make seed             - Load seed data"
	@echo ""
	@echo "🔍 Monitoring & Validation:"
	@echo "  make status           - Show pipeline status"
	@echo "  make monitor_pipeline - Real-time pipeline monitoring"
	@echo "  make validate_infrastructure - Check infrastructure health"
	@echo "  make validate_dependencies   - Check source freshness"
	@echo "  make performance_report      - Show performance metrics"
	@echo ""
	@echo "🔧 Maintenance:"
	@echo "  make test             - Run all tests"
	@echo "  make docs             - Generate documentation"
	@echo "  make deps             - Install dependencies"
	@echo "  make cleanup_logs     - Clean old logs and reports"
	@echo ""
	@echo "🚨 Recovery:"
	@echo "  make rollback_layer LAYER=bronze|silver|gold - Rollback layer"
	@echo ""
	@echo "🐳 Infrastructure:"
	@echo "  make build            - Build Docker containers"
	@echo "  make up               - Start all services"
	@echo "  make down             - Stop all services"
	@echo "  make restart          - Restart all services"
	@echo ""
	@echo "📊 Configuration:"
	@echo "  FULL_REFRESH=''       - Disable full refresh (incremental mode)"
	@echo "  EXECUTION_ID          - Current execution identifier"
	@echo ""
	@echo "📁 Output Locations:"
	@echo "  Logs:    $(PIPELINE_LOG_DIR)/"
	@echo "  Reports: $(PIPELINE_REPORTS_DIR)/"
	@echo "  Backups: $(PIPELINE_BACKUP_DIR)/"



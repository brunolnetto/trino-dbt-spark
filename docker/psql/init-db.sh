#!/bin/bash
set -e

# Utility functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }

# Configuration management
check_required_var() {
    local var_name="$1"
    local var_value="$2"
    local default_value="$3"
    
    if [ -z "$var_value" ] && [ -z "$default_value" ]; then
        log_error "Required variable $var_name is not set"
        exit 1
    fi
}

load_config() {
    # Required variables
    check_required_var "POSTGRES_USER" "$POSTGRES_USER"
    check_required_var "POSTGRES_DB" "$POSTGRES_DB"

    # Metastore configuration
    HIVE_METASTORE_USER=${HIVE_METASTORE_USER:-hive}
    HIVE_METASTORE_PASSWORD=${HIVE_METASTORE_PASSWORD:-hive123}
    HIVE_METASTORE_DB=${HIVE_METASTORE_DB:-metastore_db}

    # Metabase configuration
    MB_DB_USER=${MB_DB_USER:-metabase}
    MB_DB_PASS=${MB_DB_PASS:-metabase123}
    MB_DB_DBNAME=${MB_DB_DBNAME:-metabase}
}

print_config() {
    log_info "Using configuration:"
    echo "  📦 Metastore:"
    echo "    - Database: $HIVE_METASTORE_DB"
    echo "    - User: $HIVE_METASTORE_USER"
    echo "  📊 Metabase:"
    echo "    - Database: $MB_DB_DBNAME"
    echo "    - User: $MB_DB_USER"
}

# Database initialization functions
create_utility_functions() {
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
        -- Function to safely create a user with error handling
        CREATE OR REPLACE FUNCTION create_user_if_not_exists(
            username TEXT,
            password TEXT
        ) RETURNS void AS \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = username) THEN
                EXECUTE format('CREATE USER %I WITH PASSWORD %L', username, password);
                RAISE NOTICE 'Created user %', username;
            ELSE
                RAISE NOTICE 'User % already exists', username;
            END IF;
        END;
        \$\$ LANGUAGE plpgsql;
EOF
}

# Initialize a single database pipeline
initialize_database_pipeline() {
    local db_name="$1"
    local db_user="$2"
    local db_pass="$3"
    local description="$4"
    
    log_info "Initializing $description pipeline..."
    
    # Step 1: Create user
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
        SELECT create_user_if_not_exists('$db_user', '$db_pass');
EOF
    
    # Step 2: Create database
    if ! psql -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        log_info "Creating database $db_name..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
            CREATE DATABASE $db_name;
            ALTER DATABASE $db_name OWNER TO $db_user;
EOF
    else
        log_info "Database $db_name already exists"
    fi
    
    # Step 3: Grant privileges
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
        GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;
EOF
    
    # Step 4: Verify setup
    log_info "Verifying $description setup..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
        SELECT 
            r.rolname as username,
            d.datname as database,
            pg_catalog.has_database_privilege(r.rolname, d.datname, 'CONNECT') as has_access
        FROM pg_catalog.pg_roles r
        CROSS JOIN pg_catalog.pg_database d
        WHERE r.rolname = '$db_user'
        AND d.datname = '$db_name';
EOF
    
    log_success "$description initialization completed"
}

# Initialize Hive Metastore database
initialize_metastore() {
    initialize_database_pipeline \
        "${HIVE_METASTORE_DB}" \
        "${HIVE_METASTORE_USER}" \
        "${HIVE_METASTORE_PASSWORD}" \
        "Hive Metastore"
}

# Initialize Metabase database
initialize_metabase() {
    initialize_database_pipeline \
        "${MB_DB_DBNAME}" \
        "${MB_DB_USER}" \
        "${MB_DB_PASS}" \
        "Metabase"
}

# Main initialization process
main() {
    log_info "Starting database initialization..."
    
    # Load and validate configuration
    load_config
    print_config
    
    # Step 1: Create utility functions
    log_info "Creating utility functions..."
    
    create_utility_functions || {
        log_error "Failed to create utility functions"
        exit 1
    }
    
    # Step 2: Initialize Hive Metastore
    initialize_metastore || {
        log_error "Failed to initialize Hive Metastore"
        exit 1
    }
    
    # Step 3: Initialize Metabase
    initialize_metabase || {
        log_error "Failed to initialize Metabase"
        exit 1
    }
    
    # All database initializations completed
    log_success "All databases initialized successfully"
}

# Execute main function with error handling
main || {
    log_error "Database initialization failed"
    exit 1
}

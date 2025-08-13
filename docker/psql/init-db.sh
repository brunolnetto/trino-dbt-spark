#!/bin/bash
set -e

# Initialize Metabase database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ${METABASE_DB_USER:-metabase} WITH PASSWORD '${METABASE_DB_PASSWORD:-metabase123}';
    CREATE DATABASE ${METABASE_DB:-metabase} OWNER ${METABASE_DB_USER:-metabase};
EOSQL

echo "Database initialization completed successfully"

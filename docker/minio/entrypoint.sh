#!/usr/bin/env bash
set -euo pipefail

# Source utility scripts from the same directory where this script is
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/general_utils.sh"
source "$SCRIPT_DIR/minio_utils.sh"

# Log script execution
log_info "Starting MinIO bucket initialization..."

# Ensure required environment variables are set
ensure_var_set "MINIO_URL"
ensure_var_set "MINIO_ROOT_USER"
ensure_var_set "MINIO_ROOT_PASSWORD"
ensure_var_set "MINIO_BUCKETS"

# Display configuration
log_info "MinIO URL: $MINIO_URL"
log_info "MinIO Root User: $MINIO_ROOT_USER"
log_info "MinIO Buckets to create: $MINIO_BUCKETS"

# Call setup_minio with all required parameters
setup_minio "$MINIO_URL" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" "$MINIO_BUCKETS"

log_info "✅ MinIO bucket initialization completed successfully."
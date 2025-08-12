#!/bin/bash
set -e

# Define color codes for log messages
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[34m"
RESET="\033[0m"

# Logging functions
log_info() { echo -e "${BLUE}🔵 [INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}🟢 [OK]${RESET} $*"; }
log_warn() { echo -e "${YELLOW}🟡 [WARN]${RESET} $*"; }
log_error() { echo -e "${RED}🔴 [ERROR]${RESET} $*"; }

# Check required environment variables
for var in MINIO_URL MINIO_ROOT_USER MINIO_ROOT_PASSWORD MINIO_BUCKETS; do
  if [ -z "${!var}" ]; then
    log_error "Environment variable '$var' is required but not set."
    exit 1
  fi
done

# Set up MinIO client alias
log_info "Setting up MinIO client alias..."
mc alias set myminio "$MINIO_URL" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# Wait for MinIO server to be ready
log_info "Waiting for MinIO server to be ready..."
until mc admin info myminio >/dev/null 2>&1; do
  log_info "MinIO server not ready yet, waiting..."
  sleep 2
done
log_success "MinIO server is ready!"

# Create buckets
IFS=',' read -ra BUCKETS <<< "$MINIO_BUCKETS"
for bucket in "${BUCKETS[@]}"; do
  bucket=$(echo "$bucket" | tr -d '[:space:]')
  if [ -n "$bucket" ]; then
    log_info "Processing bucket: $bucket"
    
    # Check if bucket exists
    if mc ls myminio/$bucket >/dev/null 2>&1; then
      log_warn "Bucket '$bucket' already exists"
    else
      log_info "Creating bucket '$bucket'..."
      mc mb myminio/$bucket
      log_success "Bucket '$bucket' created"
    fi
    
    # Create policy file
    policy_file="/tmp/policy-${bucket}.json"
    cat > "$policy_file" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS":["*"]},
      "Action": [
        "s3:GetBucketLocation",
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::$bucket","arn:aws:s3:::$bucket/*"]
    }
  ]
}
EOF

    # Apply policy
    log_info "Setting policy for bucket '$bucket'..."
    mc anonymous set-json "$policy_file" "myminio/$bucket"
    log_success "Policy applied for bucket '$bucket'"
    
    # Clean up
    rm -f "$policy_file"
  fi
done

# Create a service user if needed (optional)
if [ "${CREATE_SERVICE_USER:-false}" = "true" ]; then
  SERVICE_USER="${SERVICE_USER:-service_user}"
  SERVICE_PASSWORD="${SERVICE_PASSWORD:-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)}"
  
  log_info "Creating service user '$SERVICE_USER'..."
  mc admin user add myminio "$SERVICE_USER" "$SERVICE_PASSWORD" || log_warn "User may already exist"
  
  # Create and apply a policy for the service user
  for bucket in "${BUCKETS[@]}"; do
    bucket=$(echo "$bucket" | tr -d '[:space:]')
    if [ -n "$bucket" ]; then
      POLICY_NAME="policy-$bucket"
      POLICY_FILE="/tmp/$POLICY_NAME.json"
      
      # Create policy file
      cat > "$POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::$bucket/*"]
    }
  ]
}
EOF
      
      # Apply policy
      mc admin policy create myminio "$POLICY_NAME" "$POLICY_FILE" || log_warn "Policy may already exist"
      mc admin policy attach myminio --user "$SERVICE_USER" "$POLICY_NAME"
      rm -f "$POLICY_FILE"
    fi
  done
  
  log_success "Service user '$SERVICE_USER' created with password '$SERVICE_PASSWORD'"
fi

log_success "✅ MinIO bucket initialization completed successfully!"

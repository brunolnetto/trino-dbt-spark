#!/usr/bin/env bash
set -Eeuo pipefail
# Robust and modular MinIO bucket & user setup script (bucket-list agnostic)
# Dependencies: mc (MinIO client), jq, general_utils.sh
# Usage examples:
#  MINIO_BUCKETS="warehouse,staging,raw" ./setup-minio.sh
#  ./setup-minio.sh bucket1 bucket2
#  MINIO_BUCKETS_FILE=./buckets.txt ./setup-minio.sh

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR="$CURRENT_DIR"

# Ensure helper exists
if [ ! -f "$SCRIPT_DIR/general_utils.sh" ]; then
  echo "🔴 Error: $SCRIPT_DIR/general_utils.sh not found" >&2
  return 1 2>/dev/null || exit 1
fi
source "$SCRIPT_DIR/general_utils.sh"

: "${MINIO_ENDPOINT:=http://minio:9000}"
: "${MC_ALIAS:=admin}"
: "${MC_ALIAS_TMP:=myminio-temp}"
: "${MINIO_ROOT_USER:?MINIO_ROOT_USER must be set}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD must be set}"
# MINIO_BUCKETS — comma-separated list (preferred)
# MINIO_BUCKETS_FILE — path to file (one bucket per line)
# CLI args may also be used to pass buckets

: "${ACCESS_LEN:=16}"
: "${SECRET_LEN:=20}"

###########################
# Helpers / parsing input #
###########################
sanitize_bucket() {
  # Remove leading/trailing whitespace, collapse double slashes, remove leading s3:// if present
  local b="$1"
  b="${b#"${b%%[![:space:]]*}"}"   # ltrim
  b="${b%"${b##*[![:space:]]}"}"   # rtrim
  b="${b#s3a://}"
  b="${b#s3://}"
  b="${b%/}"
  printf '%s' "$b"
}

parse_buckets() {
  local -n out=$1
  out=()

  # 1) CLI args
  if [ "$#" -gt 0 ] && [ -n "${1-}" ]; then
    # if script called with args, use them
    for arg in "$@"; do
      out+=("$(sanitize_bucket "$arg")")
    done
    return 0
  fi

  # 2) Environment variable MINIO_BUCKETS (comma separated)
  if [ -n "${MINIO_BUCKETS-}" ]; then
    IFS=',' read -ra arr <<<"$MINIO_BUCKETS"
    for b in "${arr[@]}"; do
      b="$(sanitize_bucket "$b")"
      [ -n "$b" ] && out+=("$b")
    done
    [ "${#out[@]}" -gt 0 ] && return 0
  fi

  # 3) File with buckets
  if [ -n "${MINIO_BUCKETS_FILE-}" ] && [ -f "$MINIO_BUCKETS_FILE" ]; then
    while IFS= read -r line; do
      line="$(sanitize_bucket "$line")"
      [ -n "$line" ] && out+=("$line")
    done <"$MINIO_BUCKETS_FILE"
    [ "${#out[@]}" -gt 0 ] && return 0
  fi

  # 4) Fallback to legacy MINIO_BUCKET (single bucket)
  if [ -n "${MINIO_BUCKET-}" ]; then
    out+=("$(sanitize_bucket "$MINIO_BUCKET")")
    return 0
  fi

  return 1
}

# convert bucket name into a safe policy name fragment
policy_name_from_bucket() {
  local b="$1"
  # keep alnum and -, replace others with -
  printf '%s' "publicread-$(tr '[:upper:]' '[:lower:]' <<<"$b" | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')"
}

###########################
# 1) Wait for MinIO alive #
###########################
wait_for_minio() {
  local endpoint="$1" user="$2" password="$3"
  log_info "Waiting for MinIO at $endpoint …"
  until mc alias set healthcheck "$endpoint" "$user" "$password" >/dev/null 2>&1 \
        && mc admin info healthcheck >/dev/null 2>&1; do
    log_info "Still waiting for MinIO…"
    sleep 2
  done
  mc alias remove healthcheck >/dev/null 2>&1 || true
  log_info "MinIO is healthy."
}

###########################
# 2) Ensure mc alias      #
###########################
ensure_mc_alias() {
  local alias="$1" endpoint="$2" user="$3" password="$4"
  retry 5 2 mc alias set "$alias" "$endpoint" "$user" "$password"
}

###########################
# 3) Buckets operations   #
###########################
ensure_bucket_exists() {
  local alias="$1" bucket="$2"
  if mc ls "$alias/$bucket" >/dev/null 2>&1; then
    log_warn "Bucket '$bucket' already exists."
  else
    log_info "Creating bucket '$bucket'…"
    retry 5 2 mc mb "$alias/$bucket"
    log_success "Bucket '$bucket' created."
  fi
}

###########################
# 4) Create user          #
###########################
generate_access_keys() {
  local access_key secret_key
  access_key="$(generate_random_string "$ACCESS_LEN")"
  secret_key="$(generate_random_string "$SECRET_LEN")"
  printf '%s\n%s' "$access_key" "$secret_key"
}

create_user_credentials() {
  local alias="$1" access_key="$2" secret_key="$3"
  if (( ${#access_key} < 3 || ${#access_key} > 20 )); then
    log_error "Access key must be 3–20 chars (was ${#access_key})"; return 1
  fi
  if (( ${#secret_key} < 8 || ${#secret_key} > 40 )); then
    log_error "Secret key must be 8–40 chars (was ${#secret_key})"; return 1
  fi

  log_info "Creating user '$access_key'…"
  retry 5 2 mc admin user add "$alias" "$access_key" "$secret_key" || {
    log_warn "mc admin user add failed; trying to update credentials"
    retry 3 1 mc admin user add "$alias" "$access_key" "$secret_key" || true
  }
}

wait_for_user_creation() {
  local alias="$1" user="$2"
  log_info "Waiting for user '$user' to be enabled…"
  local out
  until out="$(mc admin user info "$alias" "$user" --json 2>/dev/null)" && [[ "$out" == *'"userStatus":"enabled"'* ]]; do
    log_info "Still waiting for user to be enabled…"
    sleep 3
  done
  log_info "User '$user' is ready."
}

###########################
# 5) Policies per-bucket  #
###########################
write_policy_file_for_bucket() {
  local outpath="$1" bucket="$2"
  cat > "$outpath" <<EOF
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
}

apply_bucket_policy_to_user() {
  local alias="$1" bucket="$2" user="$3"
  local tmp_policy="/tmp/public-read-${bucket}.json"
  local policy_name
  policy_name="$(policy_name_from_bucket "$bucket")"

  write_policy_file_for_bucket "$tmp_policy" "$bucket"

  # idempotent create: check if exists, else create
  if mc admin policy info "$alias" "$policy_name" >/dev/null 2>&1; then
    log_info "Policy '$policy_name' already exists."
  else
    log_info "Uploading policy '$policy_name'…"
    retry 5 2 mc admin policy create "$alias" "$policy_name" "$tmp_policy"
  fi

  log_info "Attaching policy '$policy_name' to user '$user'…"
  retry 5 2 mc admin policy attach "$alias" --user "$user" "$policy_name"

  log_info "Applying anonymous/public JSON policy to bucket '$bucket'…"
  retry 5 2 mc anonymous set-json "$tmp_policy" "${alias}/${bucket}"

  rm -f "$tmp_policy"
  log_success "Policy applied for bucket '$bucket'."
}

###########################
# 6) Test credentials     #
###########################
setup_temporary_alias_and_verify() {
  local endpoint="$1" user="$2" secret="$3" bucket="$4"
  log_info "Testing new credentials for bucket '$bucket'…"
  retry 3 2 mc alias set "$MC_ALIAS_TMP" "$endpoint" "$user" "$secret"
  if ! mc ls "${MC_ALIAS_TMP}/${bucket}" >/dev/null 2>&1; then
    log_error "New credentials failed to list bucket '$bucket'."
    mc alias remove "$MC_ALIAS_TMP" >/dev/null 2>&1 || true
    return 1
  fi
  log_success "New credentials verified for bucket '$bucket'."
  mc alias remove "$MC_ALIAS_TMP" >/dev/null 2>&1 || true
}

###########################
# 7) Orchestration        #
###########################
setup_minio() {
  # gather buckets
  local buckets=()
  # allow passing buckets as CLI args to this function
  parse_buckets buckets "$@" || {
    log_error "No buckets provided. Set MINIO_BUCKETS (csv) or MINIO_BUCKETS_FILE or pass as args."
    return 2
  }

  wait_for_minio "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
  ensure_mc_alias "$MC_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

  # create buckets
  for b in "${buckets[@]}"; do
    ensure_bucket_exists "$MC_ALIAS" "$b"
  done

  # Generate and create user
  read -r access_key secret_key < <(generate_access_keys)
  log_info "Generated Access Key: $access_key"
  log_info "Generated Secret Key: (hidden)"

  create_user_credentials "$MC_ALIAS" "$access_key" "$secret_key"
  wait_for_user_creation "$MC_ALIAS" "$access_key"

  # policy + verify for each bucket
  for b in "${buckets[@]}"; do
    apply_bucket_policy_to_user "$MC_ALIAS" "$b" "$access_key"
    setup_temporary_alias_and_verify "$MINIO_ENDPOINT" "$access_key" "$secret_key" "$b"
  done

  echo
  log_info "[MINIO CONFIG]"
  log_info "Endpoint:    $MINIO_ENDPOINT"
  log_info "Buckets:     ${buckets[*]}"
  log_info "Access Key:  $access_key"
  log_info "Secret Key:  $(printf '******** (len=%s)' "${#secret_key}")"
}

###########################
# Entrypoint              #
###########################
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  # If called directly, allow CLI bucket args or rely on env vars
  setup_minio "$@"
fi

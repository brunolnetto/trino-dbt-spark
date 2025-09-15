#!/bin/bash

# Color definitions for log messages
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[34m"
RESET="\033[0m"

# Logging functions
log_info()    { echo -e "${BLUE}🔵 [INFO]${RESET} $*" >&2; }
log_success() { echo -e "${GREEN}🟢 [OK]${RESET} $*" >&2; }
log_warn()    { echo -e "${YELLOW}🟡 [WARN]${RESET} $*" >&2; }
log_error()   { echo -e "${RED}🔴 [ERROR]${RESET} $*" >&2; }

# Trap to catch unexpected errors
trap 'log_error "Unexpected error at line $LINENO. Exiting."' ERR

# Function to ensure a required variable is set
ensure_var_set() {
  local var_name="$1"
  if [ -z "${!var_name}" ]; then
    log_error "Environment variable '$var_name' is required but not set."
    exit 1
  fi
}

# Retry wrapper
retry() {
  local retries=${1:-5}
  local delay=${2:-2}
  shift 2
  local attempt=0
  until "$@"; do
    ((attempt++))
    if (( attempt >= retries )); then
      log_error "Command failed after $attempt attempts: $*"
      return 1
    fi
    log_warn "Command failed, retrying in $delay seconds... ($attempt/$retries)"
    sleep "$delay"
    delay=$((delay * 2))
  done
}

# Function to update or append a key-value pair in the .env file
update_env_file() {
  local key="$1"
  local value="$2"
  local env_file=".env"

  # Ensure .env exists
  touch "$env_file"

  # Use sed to replace the value if the key exists; otherwise, append the key-value pair
  if grep -q "^${key}=" "$env_file"; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$env_file" && rm -f "${env_file}.bak"
  else
    echo "${key}=${value}" >> "$env_file"
  fi
}

# Function to generate a random string
# bash-only, no external commands
generate_random_string() {
  local length=${1:-16}
  local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  for ((i=0; i<length; i++)); do
    printf '%s' "${chars:RANDOM%${#chars}:1}"
  done
  printf '\n'
}

# Export functions for external use
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f ensure_var_set
export -f update_env_file
export -f generate_random_string
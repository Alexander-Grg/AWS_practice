#!/bin/bash
# Launch the script from the terraform subdirectory

if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ]; then
    echo "Setting up environment from GitHub Secrets (Codespaces)..."
    
    export TF_VAR_db_password="${PG_PASSWORD}"
    export TF_VAR_allowed_ip="${ALLOWED_IP}"
    export TF_VAR_default_region="${AWS_DEFAULT_REGION}"
    export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"
    export TF_VAR_ip_range="${CIDRS}"
else
    echo "Setting up environment from .env file (local)..."

    if [ -f "../.env" ]; then
        set -a
        source "../.env"
        set +a
    fi

    export TF_VAR_db_password="${PG_PASSWORD}"
    export TF_VAR_allowed_ip="${ALLOWED_IP}"
    export TF_VAR_default_region="${AWS_DEFAULT_REGION}"
    export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"
    export TF_VAR_ip_range="${CIDRS}"
fi

# required_vars=("TF_VAR_db_password" "TF_VAR_default_region" "TF_VAR_aws_account_id")
# for var in "${required_vars[@]}"; do
#     if [ -z "${!var}" ]; then
#         echo "Error: $var is not set!"
#         exit 1
#     fi
# done

echo "Environment setup completed!"
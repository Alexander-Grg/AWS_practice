#!/bin/bash
# Launch this script from the Terraform directory

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "⚠️  ERROR: This script must be sourced."
    echo "Usage: . ${0}  (or source ${0})"
    exit 1
fi

if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ]; then
    echo "Detected Codespaces environment"
    export TF_VAR_is_codespaces=true
    
    export TF_VAR_db_password="${PG_PASSWORD}"
    export TF_VAR_allowed_ip="${ALLOWED_IP}"
    export TF_VAR_default_region="${AWS_DEFAULT_REGION}"
    export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"
    export TF_VAR_ip_range="${CIDRS}"
else
    echo "Detected local environment"
    
    if [ -f "../.env" ]; then
        set -a
        source "../.env"
        set +a
    fi

    export TF_VAR_is_codespaces=false
    export TF_VAR_db_password="${PG_PASSWORD}"
    export TF_VAR_allowed_ip="${ALLOWED_IP}"
    export TF_VAR_default_region="${AWS_DEFAULT_REGION}"
    export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"
    export TF_VAR_ip_range="${CIDRS}"
fi

echo "Environment: $(if [ "$TF_VAR_is_codespaces" = "true" ]; then echo "Codespaces"; else echo "Local"; fi)"
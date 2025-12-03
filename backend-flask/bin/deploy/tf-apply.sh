#!/bin/bash

export TF_VAR_db_password="${PG_PASSWORD}"
export TF_VAR_allowed_ip="${ALLOWED_IP}"
export TF_VAR_default_region="${AWS_DEFAULT_REGION}"
export TF_VAR_aws_account_id="${AWS_ACCOUNT_ID}"

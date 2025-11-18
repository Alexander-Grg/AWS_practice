#!/bin/bash
set -a
source .env
set +a

export TF_VAR_prod_connection_string=$PROD_CONNECTION_STRING
export TF_VAR_db_password=$DB_PASSWORD
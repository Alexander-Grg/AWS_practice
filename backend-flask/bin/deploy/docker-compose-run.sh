#!/bin/bash

if [[ -n "$CODESPACE_NAME" ]]; then
    echo "Starting in Codespaces mode..."
    docker-compose -f docker-compose.yml -f docker-compose.codespaces.yml "$@"
else
    echo "Starting in Local mode..."
    docker-compose -f docker-compose.yml -f docker-compose.local.yml "$@"
fi
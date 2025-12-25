#!/bin/bash

if [[ -n "$CODESPACE_NAME" ]]; then
    echo "Starting in Codespaces mode..."
    docker-compose -f docker-compose.yml -f docker-compose.codespaces.yml "$@"
else
    echo "Starting in Local mode..."
    
    if [ -f .env ]; then
        echo "Loading .env variables..."
        set -a      
        source .env
        set +a 
    fi

    docker-compose -f docker-compose.yml -f docker-compose.local.yml "$@"
fi
#!/usr/bin/env bash
# IMPORTANT: use "source", not "./setup-env.sh"
#   source ./setup-env.sh

export SENZING_ENGINE_CONFIGURATION_JSON='{
  "PIPELINE": {
    "CONFIGPATH": "/etc/opt/senzing",
    "RESOURCEPATH": "/opt/senzing/er/resources",
    "SUPPORTPATH": "/opt/senzing/data"
  },
  "SQL": {
    "CONNECTION": "postgresql://senzing:senzing@host.docker.internal:5433:G2?sslmode=disable"
  }
}'

echo "SENZING_ENGINE_CONFIGURATION_JSON is set (PostgreSQL on localhost:5433)."

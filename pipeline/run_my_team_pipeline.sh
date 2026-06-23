#!/usr/bin/env bash
# Pipeline variant for my_team Parquet (uses learning/map_my_team_parquet.py).
# Called by run_my_team_from_minio.sh — or run directly after setup-minio-env.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${SENZING_ENGINE_CONFIGURATION_JSON:-}" ]]; then
  echo "ERROR: Run 'source ./setup-env.sh' first."
  exit 1
fi

S3_URI="${S3_URI:-s3://senzing-incoming/my_team/}"
INCOMING_DIR="${INCOMING_DIR:-my_team}"
PARQUET_FILE="${PARQUET_FILE:-my_team.parquet}"
JSONL_FILE="${JSONL_FILE:-mapped_my_team_pq.jsonl}"
DATA_SOURCE="${SENZING_DATA_SOURCE:-MY_TEAM_PQ}"
SKIP_SNAPSHOT="${SKIP_SNAPSHOT:-0}"
PYTHON_IMAGE="python:3.12-slim"

INCOMING="${ROOT}/incoming/${INCOMING_DIR}"
STAGING="${ROOT}/staging"
PROCESSED_LOG="${ROOT}/staging/.processed_files.log"
PARQUET_PATH="${INCOMING}/${PARQUET_FILE}"
JSONL_PATH="${STAGING}/${JSONL_FILE}"

mkdir -p "$INCOMING" "$STAGING"

echo "=== Pipeline: ${DATA_SOURCE} ==="

echo "=== Step 1: Acquire Parquet ==="
if [[ -n "$S3_URI" ]]; then
  AWS_ARGS=()
  if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
    AWS_ARGS+=(--endpoint-url "$AWS_ENDPOINT_URL")
  fi
  rm -rf "${INCOMING:?}"/*
  mkdir -p "$INCOMING"
  aws s3 sync "$S3_URI" "$INCOMING" "${AWS_ARGS[@]}" --exclude "*" --include "*.parquet"
fi

if [[ ! -f "$PARQUET_PATH" ]]; then
  echo "ERROR: Expected Parquet: $PARQUET_PATH"
  exit 1
fi

FILE_KEY="${DATA_SOURCE}-${PARQUET_FILE}-$(stat -f %m "$PARQUET_PATH" 2>/dev/null || stat -c %Y "$PARQUET_PATH")"
if [[ -f "$PROCESSED_LOG" ]] && grep -q "^${FILE_KEY}$" "$PROCESSED_LOG"; then
  echo "Already processed — remove '${FILE_KEY}' from $PROCESSED_LOG to reload."
  exit 0
fi

echo ""
echo "=== Step 2: Map Parquet -> JSONL ==="
docker run --rm \
  -e PARQUET_INPUT="/data/incoming/${INCOMING_DIR}/${PARQUET_FILE}" \
  -e JSONL_OUTPUT="/data/staging/${JSONL_FILE}" \
  -e SENZING_DATA_SOURCE="$DATA_SOURCE" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python learning/map_my_team_parquet.py'

echo ""
echo "=== Step 3: Load ==="
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f "/data/staging/${JSONL_FILE}"

if [[ "$SKIP_SNAPSHOT" != "1" ]]; then
  echo ""
  echo "=== Step 4: Snapshot ==="
  docker run --rm -u "$(id -u)" -v "${ROOT}:/data" -w /data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot
fi

echo "$FILE_KEY" >> "$PROCESSED_LOG"
echo "=== Done: ${DATA_SOURCE} ==="

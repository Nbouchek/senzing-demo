#!/usr/bin/env bash
# MinIO = local S3-compatible API. Source after setup-env.sh:
#   source ./setup-env.sh
#   source ./setup-minio-env.sh

export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:9000
export S3_URI=s3://senzing-incoming/customers/

echo "MinIO S3 env set (endpoint: $AWS_ENDPOINT_URL, bucket path: $S3_URI)"

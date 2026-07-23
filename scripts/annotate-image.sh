#!/usr/bin/env bash
# Annotates container images with the GCP Marketplace service name.
# Usage: ./annotate-image.sh <SERVICE_NAME> <IMAGE_URI_WITH_TAG>
#
# Example:
#   ./annotate-image.sh \
#     "services/my-product.endpoints.my-project.cloud.goog" \
#     "us-docker.pkg.dev/my-project/my-repo/py-app:1.0.0"

set -euo pipefail

SERVICE_NAME="${1:?Usage: $0 <SERVICE_NAME> <IMAGE_URI>}"
IMAGE_URI="${2:?Usage: $0 <SERVICE_NAME> <IMAGE_URI>}"

echo "Annotating ${IMAGE_URI} with service name: ${SERVICE_NAME}"
crane mutate "${IMAGE_URI}" \
  --annotation "com.googleapis.cloudmarketplace.product.service.name=${SERVICE_NAME}"

echo "Verifying annotation..."
crane manifest "${IMAGE_URI}" | jq '.annotations'
echo "Done."

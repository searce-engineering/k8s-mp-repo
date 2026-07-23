#!/usr/bin/env bash
# Packages the terraform/ directory into a zip and uploads it to GCS.
# Usage: ./package-and-upload.sh <VERSION> <GCS_BUCKET> <PRODUCT_NAME>
#
# Example:
#   ./package-and-upload.sh 1.0.0 mp-gke-tf-modules sample-app

set -euo pipefail

VERSION="${1:?Usage: $0 <VERSION> <GCS_BUCKET> <PRODUCT_NAME>}"
BUCKET="${2:?Usage: $0 <VERSION> <GCS_BUCKET> <PRODUCT_NAME>}"
PRODUCT="${3:?Usage: $0 <VERSION> <GCS_BUCKET> <PRODUCT_NAME>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ZIP_NAME="${PRODUCT}-tf-module-${VERSION}.zip"
ZIP_PATH="${SCRIPT_DIR}/${ZIP_NAME}"

echo "Packaging terraform module..."
cd "${ROOT_DIR}/terraform"
zip -r "${ZIP_PATH}" ./* -x "**/.*" -x "**.terraform*" -x "**terraform.tfstate*"
cd "${ROOT_DIR}"

echo "Uploading to gs://${BUCKET}/${PRODUCT}/${VERSION}/${ZIP_NAME}"
gsutil cp "${ZIP_PATH}" "gs://${BUCKET}/${PRODUCT}/${VERSION}/${ZIP_NAME}"

echo "Done. Module available at:"
echo "  gs://${BUCKET}/${PRODUCT}/${VERSION}/${ZIP_NAME}"

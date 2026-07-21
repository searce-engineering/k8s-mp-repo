# ─────────────────────────────────────────────────────────────────────────────
# GCP Marketplace Deployer Image
#
# Build context must be the repo root (gcp-marketplace-byol/), not deployer/:
#   docker build -f deployer/Dockerfile -t $DEPLOYER_IMAGE .
#
# Directory layout inside the image:
#   /data/chart/         ← main Helm chart (used for customer deployments)
#   /data/schema.yaml    ← main schema (drives the Marketplace UI form)
#   /data-test/chart/    ← apptest Helm chart (overlaid during mpdev verify)
#   /data-test/schema.yaml ← test schema overlay (injects test license values)
# ─────────────────────────────────────────────────────────────────────────────
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest

LABEL "com.googleapis.cloudmarketplace.product.service.name"="services/services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

# ── Main deployment artifacts ─────────────────────────────────────────────
COPY chart/gcp-mp-poc-k8s /data/chart
COPY schema.yaml /data/

# ── Verification test artifacts ───────────────────────────────────────────
# /data-test is overlaid onto /data by mpdev verify before running tests.
# The tester Pod template and schema overlay live here.
# COPY ../apptest/deployer/chart/    /data-test/chart/
# COPY ../apptest/deployer/schema.yaml /data-test/schema.yaml

# ── Timeouts ──────────────────────────────────────────────────────────────
# WAIT_FOR_READY_TIMEOUT: seconds to wait for all app resources to become
#   Ready before starting the tester Pod.
# TESTER_TIMEOUT: seconds to wait for the tester Pod to exit after launch.
ENV WAIT_FOR_READY_TIMEOUT=300
ENV TESTER_TIMEOUT=300
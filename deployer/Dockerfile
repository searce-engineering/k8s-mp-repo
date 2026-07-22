# FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm_onbuild:latest

# LABEL "com.googleapis.cloudmarketplace.product.service.name"="services/services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

# RUN apt-get update && \
#     apt-get upgrade -y && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*


# ─────────────────────────────────────────────────────────────────────────────
# GCP Marketplace Deployer Image
# ─────────────────────────────────────────────────────────────────────────────
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest

LABEL "com.googleapis.cloudmarketplace.product.service.name"="services/services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

# ── Main deployment artifacts ─────────────────────────────────────────────
COPY schema.yaml /data/

# The deployer script explicitly requires a .tar.gz file that extracts a folder named "chart".
# We copy to a temp dir, then tar it directly into /data/chart/
COPY chart/ /tmp/main/chart
RUN mkdir -p /data/chart && \
    tar -czvf /data/chart/app.tar.gz -C /tmp/main chart

# ── Verification test artifacts ───────────────────────────────────────────
COPY apptest/deployer/schema.yaml /data-test/

# Package the test chart exactly the same way for the verification step
COPY apptest/deployer/chart /tmp/test/chart
RUN mkdir -p /data-test/chart && \
    tar -czvf /data-test/chart/test.tar.gz -C /tmp/test chart

# ── Timeouts ──────────────────────────────────────────────────────────────
ENV WAIT_FOR_READY_TIMEOUT=300
ENV TESTER_TIMEOUT=300
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:latest

# Copy test schema overlay for automated verification (provides dummy values for required fields)
COPY apptest/schema.yaml /data-test/schema.yaml

# Update and upgrade all Ubuntu OS-level packages to patch vulnerabilities
USER root
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

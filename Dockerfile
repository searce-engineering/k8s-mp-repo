# Google Cloud Marketplace Helm-based Deployer Base Image
# Copies all files in this directory (including Helm charts and schemas) into the Deployer container during the build stage.
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:latest

# Update and upgrade all Ubuntu OS-level packages to patch vulnerabilities
USER root
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

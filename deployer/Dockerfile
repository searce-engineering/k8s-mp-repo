# We use Google's official Helm deployer base image
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:latest

# Update and upgrade all Ubuntu OS-level packages to patch vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the Helm chart and the schema into the container at the expected paths
COPY chart /data/chart
COPY schema.yaml /data/


# We use Google's official Helm deployer base image
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:latest

# The Marketplace requirement: OCI Annotation
LABEL com.googleapis.cloudmarketplace.product.service.name="services/ibm-poc-app-k8s.endpoints.searce-cloud-products.cloud.goog"

# Copy the Helm chart and the schema into the container at the expected paths
# COPY chart /data/chart
# COPY schema.yaml /data/

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm_onbuild:latest

LABEL "com.googleapis.cloudmarketplace.product.service.name"="services/services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

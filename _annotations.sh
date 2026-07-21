export SERVICE_NAME="services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

crane mutate us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME
export SERVICE_NAME="services/ibm-poc-app-k8s.endpoints.searce-cloud-products.cloud.goog"

crane mutate us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME

crane mutate us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0 \
  --annotation com.googleapis.cloudmarketplace.product.service.name=$SERVICE_NAME
FROM nginx:1.25-alpine
# The Marketplace requirement: OCI Annotation for service name
LABEL com.googleapis.cloudmarketplace.product.service.name="services/my-poc-service.endpoints.my-project.cloud.goog"

COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80

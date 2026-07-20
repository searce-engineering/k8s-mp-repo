##  App  Image ##
## ## ## ## ## ##

## Linux
docker buildx build \
  --provenance=false \
  --sbom=false \
  --no-cache \
  -t my-poc-app-linux:1.0.0 \
  ./app

## Deployer Image ##
## ## ## ## ## ## ##

## Linux
docker buildx build \
  --provenance=false \
  --sbom=false \
  --no-cache \
  -f deployer/Dockerfile \
  -t my-poc-deployer-linux:1.0.0 \
  .

# Tag App Images
docker tag my-poc-app-linux:1.0.0 us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0
docker tag my-poc-app-linux:1.0.0 us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0.0

# Tag Deployer Images
docker tag my-poc-deployer-linux:1.0.0 us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0
docker tag my-poc-deployer-linux:1.0.0 us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0.0

#Push to Artifact Registry
docker push us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0
docker push us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app:1.0.0
docker push us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0
docker push us-docker.pkg.dev/searce-cloud-products/mp-poc-k8s-denis/my-poc-app/deployer:1.0.0
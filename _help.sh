##  App  Image ##
## ## ## ## ## ##

## Linux
docker buildx build \
  --provenance=false \
  --sbom=false \
  --no-cache \
  --platform linux/amd64 \
  -t app:1.0.0 \
  ./app

## Deployer Image ##
## ## ## ## ## ## ##

## Linux
docker buildx build \
  --provenance=false \
  --sbom=false \
  --no-cache \
  --platform linux/amd64 \
  -f deployer/Dockerfile \
  -t deployer:1.0.0 \
  .

# Tag App Images
docker tag app:1.0.0 us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0
docker tag app:1.0.0 us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0.0

# Tag Deployer Images
docker tag deployer:1.0.0 us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0
docker tag deployer:1.0.0 us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0.0

#Push to Artifact Registry
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app:1.0.0
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0.0
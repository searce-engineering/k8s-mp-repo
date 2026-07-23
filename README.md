# GCP Marketplace GKE Terraform POC

Minimal proof-of-concept for publishing a containerized application to Google Cloud Marketplace using the **Terraform-based GKE integration**.

## Directory Structure

```
tf-mp-poc/
├── README.md
├── py-app/                     # Application source
│   ├── main.py
│   └── Dockerfile
├── chart/                      # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── application.yaml    # GKE Marketplace Application CRD
├── helm-docker/                # OCI image packaging for the chart
│   └── Dockerfile
├── scripts/
│   ├── annotate-image.sh       # Apply Marketplace OCI annotations
│   └── package-and-upload.sh   # Zip and upload Terraform module to GCS
└── terraform/                  # Marketplace Terraform module
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── schema.yaml             # Image-to-variable mapping for Marketplace
```

## Prerequisites

- Google Cloud SDK (`gcloud`) authenticated with a publisher project
- Docker with `buildx` support
- `crane` CLI ([install guide](https://github.com/google/go-containerregistry/tree/main/cmd/crane))
- `cft` CLI (Cloud Foundation Toolkit) for metadata generation
- Terraform >= 1.4

## Quick Start

Replace all instances of `searce-cloud-products`, `us`, and `gcp-mp-poc-tf-k8s` with your values.

### 1. Create Artifact Registry

```bash
gcloud artifacts repositories create gcp-mp-poc-tf-k8s \
    --repository-format=docker \
    --location=us \
    --project=searce-cloud-products
```

### 2. Build and Push Images

```bash
# Application image
docker buildx build --platform=linux/amd64 \
    --provenance=false --sbom=false --no-cache \
    -t us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0.0 ./py-app

docker tag us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0.0 \
    us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0

docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0.0
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0

# Helm chart image
docker buildx build --platform=linux/amd64 \
    --provenance=false --sbom=false --no-cache \
    -t us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0.0 \
    -f ./helm-docker/Dockerfile .

docker tag us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0.0 \
    us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0

docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0.0
docker push us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0
```

### 3. Annotate Images

```bash
export SERVICE_NAME="services/gcp-mp-poc-tf-k8s.endpoints.searce-cloud-products.cloud.goog"

# Annotate all image tags
./scripts/annotate-image.sh "$SERVICE_NAME" us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0.0
./scripts/annotate-image.sh "$SERVICE_NAME" us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app:1.0
./scripts/annotate-image.sh "$SERVICE_NAME" us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0.0
./scripts/annotate-image.sh "$SERVICE_NAME" us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart:1.0
```

### 4. Generate Metadata (CFT)

```bash
cft blueprint metadata -p ./terraform -q
cft blueprint metadata -p ./terraform -q -d
cft blueprint metadata -p ./terraform -v
```

This produces `metadata.yaml` and `metadata.display.yaml` inside `terraform/`.

### 5. Package and Upload

```bash
chmod +x ./scripts/package-and-upload.sh
./scripts/package-and-upload.sh 1.0.0 gcs-us-gcp-mp-poc-tf-k8s gcp-mp-poc-tf-k8s
```

### 6. Register in Producer Portal

1. Open the [Producer Portal](https://console.cloud.google.com/producer-portal/).
2. Add Product → **GKE App (via Terraform)**.
3. Note the generated **Service Name** (use it in step 3 above).
4. In Deployment Package, provide the Helm chart Artifact Registry URI and select the annotated digest.
5. Provide the GCS URI for the Terraform zip.
6. Select required IAM roles and default release.
7. Save and Validate.

## Local Testing

```bash
cd terraform
terraform init
terraform apply \
    -var="project_id=searce-cloud-products" \
    -var="cluster_name=mp-gke-tf-poc" \
    -var="cluster_location=us-central1-a" \
    -var="namespace=test-ns" \
    -var="image_repo=us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/py-app" \
    -var="image_tag=1.0.0" \
    -var="helm_chart_repo=us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-tf-k8s/chart" \
    -var="helm_chart_version=1.0.0"

# Verify
kubectl get pods -n test-ns
kubectl port-forward svc/sample-app-svc -n test-ns 8080:80
# Visit http://localhost:8080
```

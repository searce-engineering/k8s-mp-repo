# GCP Marketplace BYOL Kubernetes — Full Deployment Guide

> **Goal**: Publish a Python Flask app as a BYOL (Bring Your Own License)
> Kubernetes product on GCP Marketplace.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Prerequisites](#3-prerequisites)
4. [Phase 1 — Local Development & Testing](#4-phase-1--local-development--testing)
5. [Phase 2 — GCP Setup](#5-phase-2--gcp-setup)
6. [Phase 3 — Build & Push Images](#6-phase-3--build--push-images)
7. [Phase 4 — GKE Testing](#7-phase-4--gke-testing)
8. [Phase 5 — GCP Marketplace Partner Portal Setup](#8-phase-5--gcp-marketplace-partner-portal-setup)
9. [Phase 6 — Publishing & Review](#9-phase-6--publishing--review)
10. [Phase 7 — Customer Purchase & Deployment Flow](#10-phase-7--customer-purchase--deployment-flow)
11. [BYOL License Flow Explained](#11-byol-license-flow-explained)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Marketplace                          │
│                                                             │
│  Customer clicks "Deploy"                                   │
│       │                                                     │
│       ▼                                                     │
│  Deployer Image  ────────────► GKE Cluster (customer's)     │
│  (Helm chart)                      │                        │
│                                    │  K8s Secret            │
│                              ┌─────┴──────┐                 │
│                              │  Your App  │                 │
│                              │  (Flask)   │◄── LICENSE_KEY  │
│                              └────────────┘                 │
└─────────────────────────────────────────────────────────────┘

BYOL Flow:
  1. Customer buys license key from you (outside Marketplace)
  2. Customer enters key during Marketplace deployment
  3. Key is stored in a Kubernetes Secret
  4. App reads key from env var, validates with HMAC
  5. App serves traffic only when key is valid
```

**Two images you publish to GCR:**

| Image | Purpose |
|---|---|
| `gcp-mp-poc-k8s` | Your actual Flask application |
| `gcp-mp-poc-k8s/deployer` | Marketplace deployer — wraps the Helm chart |

---

## 2. Project Structure

```
gcp-marketplace-byol/
├── app/
│   ├── app.py                   # Flask app with BYOL license verification
│   ├── requirements.txt
│   ├── Dockerfile               # Multi-stage, non-root, production-ready
│   └── .dockerignore
├── chart/                       # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── schema.yaml              # ← GCP Marketplace deployer UI schema
│   └── templates/
│       ├── _helpers.tpl
│       ├── application.yaml     # ← Required Application CR for Marketplace
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── serviceaccount.yaml
│       └── secret.yaml          # Stores LICENSE_KEY + LICENSE_SECRET
└── deployer/
    └── Dockerfile               # Extends gcr.io/cloud-marketplace-tools/...
```

---

## 3. Prerequisites

### Tools to Install

```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
gcloud components install kubectl

# Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker
# Follow: https://docs.docker.com/engine/install/

# mpdev — Marketplace developer tools
docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest
alias mpdev='docker run --rm -it \
  -v $HOME/.config/gcloud:/root/.config/gcloud \
  gcr.io/cloud-marketplace-tools/k8s/dev:latest'
```

### Accounts & Access

- GCP account with billing enabled
- GCP Marketplace Partner account (apply at https://cloud.google.com/marketplace/docs/partners)
- Docker Hub or GCR access

---

## 4. Phase 1 — Local Development & Testing

### 4a. Test the App Locally with Docker

```bash
cd gcp-marketplace-byol/app

# Build the image
docker build -t gcp-mp-poc-k8s:local .

# Generate a valid license key (run once, save both values)
python3 - <<'EOF'
import hmac, hashlib
secret = "my-test-secret"
app_name = "gcp-mp-poc-k8s"
key = hmac.new(secret.encode(), app_name.encode(), hashlib.sha256).hexdigest()
print(f"LICENSE_KEY    = {key}")
print(f"LICENSE_SECRET = {secret}")
EOF

# Run the container with the generated values
docker run -p 8080:8080 \
  -e LICENSE_KEY="<output-from-above>" \
  -e LICENSE_SECRET="my-test-secret" \
  gcp-mp-poc-k8s:local

# Test endpoints
curl http://localhost:8080/healthz          # → {"status":"ok"}
curl http://localhost:8080/license/status   # → {"licensed":true}
curl http://localhost:8080/                 # → Hello message
curl http://localhost:8080/api/data         # → Sample data

# Test with invalid key
docker run -p 8081:8080 -e LICENSE_KEY="bad-key" -e LICENSE_SECRET="my-test-secret" gcp-mp-poc-k8s:local
curl http://localhost:8081/                 # → 403 license_invalid
```

### 4b. Test the Helm Chart Locally (with kind or minikube)

```bash
# Start a local cluster
kind create cluster --name byol-test
# or: minikube start

# Create the license secret manually for local test
kubectl create namespace byol-test
kubectl create secret generic byol-license-secret \
  --namespace byol-test \
  --from-literal=licenseKey="<your-license-key>" \
  --from-literal=licenseSecret="my-test-secret"

# Lint the chart
helm lint ./chart

# Dry-run install
helm install byol-app ./chart \
  --namespace byol-test \
  --set image.repository=gcp-mp-poc-k8s \
  --set image.tag=local \
  --dry-run

# Real install (load image into kind first)
kind load docker-image gcp-mp-poc-k8s:local --name byol-test
helm install byol-app ./chart \
  --namespace byol-test \
  --set image.repository=gcp-mp-poc-k8s \
  --set image.tag=local

# Verify
kubectl get pods -n byol-test
kubectl port-forward svc/byol-app-gcp-mp-poc-k8s 8080:80 -n byol-test
curl http://localhost:8080/healthz
```

---

## 5. Phase 2 — GCP Setup

### 5a. Create & Configure GCP Project

```bash
# Set your project ID (use your actual project)
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export REGISTRY="gcr.io"     # or use Artifact Registry: us-central1-docker.pkg.dev

gcloud projects create $PROJECT_ID --name="BYOL Marketplace App"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

# Authenticate Docker with GCR
gcloud auth configure-docker
```

### 5b. Create Artifact Registry (Recommended over GCR)

```bash
# Create a Docker repository in Artifact Registry
gcloud artifacts repositories create gcp-mp-poc-k8s \
  --repository-format=docker \
  --location=$REGION \
  --description="BYOL Python App for GCP Marketplace"

# Auth Docker with Artifact Registry
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Update your image path variable
export IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/gcp-mp-poc-k8s"
```

### 5c. Create GKE Cluster for Testing

```bash
gcloud container clusters create byol-test-cluster \
  --zone ${REGION}-a \
  --num-nodes 2 \
  --machine-type e2-medium \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 4

# Get credentials
gcloud container clusters get-credentials byol-test-cluster \
  --zone ${REGION}-a

# Install the Application CRD (required by Marketplace)
kubectl apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/application/master/config/crd/bases/app.k8s.io_applications.yaml
```

---

## 6. Phase 3 — Build & Push Images

### 6a. Tag & Push the App Image

```bash
export APP_VERSION="1.0.0"
export APP_IMAGE="${IMAGE_BASE}/app:${APP_VERSION}"

cd gcp-marketplace-byol/app

docker build -t $APP_IMAGE .
docker push $APP_IMAGE

# Also tag as latest
docker tag $APP_IMAGE ${IMAGE_BASE}/app:latest
docker push ${IMAGE_BASE}/app:latest

echo "App image: $APP_IMAGE"
```

### 6b. Update values.yaml with the Real Image Path

Edit `chart/values.yaml`:
```yaml
image:
  repository: us-central1-docker.pkg.dev/YOUR_PROJECT_ID/gcp-mp-poc-k8s/app
  tag: "1.0.0"
```

### 6c. Build & Push the Deployer Image

```bash
export DEPLOYER_IMAGE="${IMAGE_BASE}/deployer:${APP_VERSION}"

# The deployer Dockerfile references ./chart — build from repo root
cd gcp-marketplace-byol

docker build -f deployer/Dockerfile -t $DEPLOYER_IMAGE .
docker push $DEPLOYER_IMAGE

echo "Deployer image: $DEPLOYER_IMAGE"
```

### 6d. Make Images Publicly Readable (Required by Marketplace)

```bash
# Grant public read on both images
gsutil iam ch allUsers:objectViewer gs://artifacts.${PROJECT_ID}.appspot.com

# Or with Artifact Registry:
gcloud artifacts repositories add-iam-policy-binding gcp-mp-poc-k8s \
  --location=$REGION \
  --member="allUsers" \
  --role="roles/artifactregistry.reader"
```

---

## 7. Phase 4 — GKE Testing

### 7a. Install via Helm on GKE (Full Smoke Test)

```bash
kubectl create namespace byol-prod

# Create license secret
kubectl create secret generic byol-license-secret \
  --namespace byol-prod \
  --from-literal=licenseKey="<your-license-key>" \
  --from-literal=licenseSecret="<your-hmac-secret>"

# Install the Helm chart
helm install byol-app ./chart \
  --namespace byol-prod \
  --set image.repository="${IMAGE_BASE}/app" \
  --set image.tag="${APP_VERSION}"

# Watch rollout
kubectl rollout status deployment/byol-app-gcp-mp-poc-k8s -n byol-prod

# Expose for testing
kubectl port-forward svc/byol-app-gcp-mp-poc-k8s 8080:80 -n byol-prod &
curl http://localhost:8080/
curl http://localhost:8080/license/status
```

### 7b. Validate with mpdev

```bash
# mpdev verify runs the Marketplace pre-submission checks
mpdev verify \
  --deployer=$DEPLOYER_IMAGE \
  --parameters='{"namespace":"byol-verify","name":"byol-test"}'
```

---

## 8. Phase 5 — GCP Marketplace Partner Portal Setup

### 8a. Join the GCP Marketplace Partner Program

1. Go to https://cloud.google.com/marketplace/docs/partners
2. Click **"Become a Partner"** and fill out the ISV application
3. Wait for approval (typically 2–5 business days)
4. You'll get access to the **Producer Portal** at https://console.cloud.google.com/producer-portal

### 8b. Create a New Product Listing

In Producer Portal → **Products** → **Add Product** → **Kubernetes App**:

| Field | Value |
|---|---|
| Product ID | `gcp-mp-poc-k8s` |
| Product Name | `BYOL Python App` |
| Pricing Model | **BYOL** |
| Category | Choose most appropriate |

### 8c. Configure the Product Details

**Overview tab:**
- Display name, description, tagline
- Product icon (PNG, 512×512)
- Screenshots (at least 3)
- Documentation URL
- Support URL / email

**Pricing tab:**
- Select **BYOL** — no per-unit Marketplace billing
- Add a note: "Contact vendor to purchase a license key before deploying"

**Technical tab — fill in your images:**

```
App container image:
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/gcp-mp-poc-k8s/app:1.0.0

Deployer image:
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/gcp-mp-poc-k8s/deployer:1.0.0
```

### 8d. Grant Marketplace Service Account Access to Your Images

```bash
# GCP Marketplace needs to pull and verify your images
# Get the Marketplace service account email from Producer Portal → Settings

export MARKETPLACE_SA="cloud-marketplace@system.gserviceaccount.com"

gcloud artifacts repositories add-iam-policy-binding gcp-mp-poc-k8s \
  --location=$REGION \
  --member="serviceAccount:${MARKETPLACE_SA}" \
  --role="roles/artifactregistry.reader"
```

---

## 9. Phase 6 — Publishing & Review

### 9a. Run Pre-submission Validation

```bash
# Full verification against Marketplace requirements
mpdev verify \
  --deployer=$DEPLOYER_IMAGE

# Check the schema is valid
mpdev schema validate ./chart/schema.yaml
```

### 9b. Submit for Review

In Producer Portal:
1. Go to your product listing
2. Review all tabs for completeness
3. Click **"Submit for Review"**
4. Google reviews for security, functional correctness, and policy compliance
5. Typical review time: **5–10 business days**
6. You'll receive feedback via email; address any issues and resubmit

### 9c. Version Updates (Post-Launch)

```bash
# Bump version
export APP_VERSION="1.1.0"
export APP_IMAGE="${IMAGE_BASE}/app:${APP_VERSION}"
export DEPLOYER_IMAGE="${IMAGE_BASE}/deployer:${APP_VERSION}"

# Update Chart.yaml: version and appVersion
# Update values.yaml: image.tag

docker build -t $APP_IMAGE app/
docker push $APP_IMAGE

docker build -f deployer/Dockerfile -t $DEPLOYER_IMAGE .
docker push $DEPLOYER_IMAGE

# In Producer Portal → create a new Version → submit for review
```

---

## 10. Phase 7 — Customer Purchase & Deployment Flow

Once published, this is what a customer experiences:

### Customer Steps

1. **Find your product** on https://console.cloud.google.com/marketplace
2. **Click "Get Started"** — since BYOL, they are directed to purchase a license from you
3. **Contact you** (via link/email you provide) → you issue them a `licenseKey` + `licenseSecret`
4. **Click "Deploy"** on the Marketplace listing
5. **Fill the configuration form** (from your schema.yaml):
   - Namespace
   - Replica count
   - **BYOL License Key** (they paste the key you issued)
   - **License Validation Secret** (they paste the HMAC secret you issued)
6. **Click Deploy** — Marketplace launches the deployer image into their GKE cluster
7. The deployer runs `helm install`, which creates the Secret and Deployment
8. App validates the key on every request; `/readyz` returns 503 until key is valid

---

## 11. BYOL License Flow Explained

```
You (Vendor)                        Customer
────────────                        ────────
Generate license pair:
  key    = HMAC(secret, app_name)
  secret = "random-secret-value"
            │
            │  Email / portal
            ▼
                                    Enter key+secret in
                                    Marketplace deploy UI
                                            │
                                            ▼
                                    K8s Secret created:
                                      licenseKey: <key>
                                      licenseSecret: <secret>
                                            │
                                            ▼
                                    Pod env vars injected
                                            │
                                    app.py: verify_license()
                                      HMAC(secret, app_name)
                                      == provided key? ✓
```

**To generate a license key for a customer:**

```python
import hmac, hashlib, secrets

def generate_license(app_name: str) -> tuple[str, str]:
    """Returns (license_key, license_secret)"""
    license_secret = secrets.token_hex(32)          # 64-char hex secret
    license_key    = hmac.new(
        license_secret.encode(),
        app_name.encode(),
        hashlib.sha256
    ).hexdigest()
    return license_key, license_secret

key, secret = generate_license("gcp-mp-poc-k8s")
print(f"LICENSE_KEY    = {key}")
print(f"LICENSE_SECRET = {secret}")
```

---

## 12. Troubleshooting

| Problem | Solution |
|---|---|
| Pod stuck in `Init:0/1` | `kubectl describe pod <name>` — usually image pull error; check image is public |
| 403 on all endpoints | License key mismatch — recreate the Secret with correct values |
| `mpdev verify` fails | Check schema.yaml has all required fields; check image paths are correct |
| Marketplace can't pull image | Add Marketplace SA as `artifactregistry.reader` on your repo |
| Deployer image not found | Ensure deployer Dockerfile copies `chart/` and `schema.yaml` correctly |
| `Application` CR not showing | Install Application CRD: `kubectl apply -f https://...app.k8s.io_applications.yaml` |
| Review rejected | Address all feedback in Producer Portal; common issues: missing health probes, running as root, no resource limits |

### Useful Commands

```bash
# View app logs
kubectl logs -l app.kubernetes.io/name=gcp-mp-poc-k8s -n byol-prod

# Describe the Application CR
kubectl describe application byol-app -n byol-prod

# Check secret was created
kubectl get secret byol-license-secret -n byol-prod -o jsonpath='{.data.licenseKey}' | base64 -d

# Helm status
helm status byol-app -n byol-prod

# Uninstall
helm uninstall byol-app -n byol-prod
```

---

## Key GCP Marketplace Links

- Partner Program: https://cloud.google.com/marketplace/docs/partners
- K8s App Packaging Guide: https://cloud.google.com/marketplace/docs/partners/kubernetes/create-app-package
- Marketplace Tools (mpdev): https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools
- Application CRD: https://github.com/kubernetes-sigs/application
- Producer Portal: https://console.cloud.google.com/producer-portal
- Schema Reference: https://cloud.google.com/marketplace/docs/partners/kubernetes/reference/schema

---

*Generated for GCP Marketplace BYOL Kubernetes POC — replace all `YOUR_PROJECT_ID`, image paths, and license secrets with real values before deploying.*

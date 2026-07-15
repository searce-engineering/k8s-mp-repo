# IBM Watsonx GKE BYOL - Marketplace Package

This directory contains the Google Cloud GKE Marketplace packaging configs for the **BYOL License Key verification POC**.

## Directory Layout
* `Dockerfile` - Builds the Helm-based deployer container image.
* `schema.yaml` - Defines the user inputs (pasted license key) for the Google Console UI.
* `chart/gke-mp-poc-app/` - The core Helm chart, containing deployment manifests.
* `apptest/` - Contains automated dry-run variables for verification.

---

## How to Test This GKE Package in Sandbox

### Step 1: Set environment variables
Specify your target Registry path:
```bash
export REGISTRY="gcr.io/your-sandbox-project-id/gke-mp-poc"
```

### Step 2: Build & Push the core application container
Go to the `app/` folder (the sister directory to this one) and build the application:
```bash
cd ../app
docker build -t $REGISTRY/app:1.0.0 .
docker push $REGISTRY/app:1.0.0
```

### Step 3: Build & Push the Deployer Container
Come back to this directory and build the deployer image (which automatically bakes in your charts and schemas):
```bash
cd ../gke
docker build -t $REGISTRY/deployer:1.0.0 .
docker push $REGISTRY/deployer:1.0.0
```

### Step 4: Validate locally using `mpdev`
Verify that your schemas, Helm charts, and deployment configs conform to Google GKE Marketplace standards:
```bash
# Doctor check (ensures Docker is running and GKE is connected)
mpdev doctor

# Dry-run validation of the deployer package
mpdev verify --deployer=$REGISTRY/deployer:1.0.0
```

---

## Architecture Flow

1. The customer deploys this app via Google Console and pastes their **SaaS License Key**.
2. Google GKE Deployer starts up a temporary Pod and deploys your Helm chart.
3. Your application pod boots up inside GKE, extracts the `LICENSE_KEY` environment variable from the Kubernetes secret, and securely validates it with your running SaaS API backend.

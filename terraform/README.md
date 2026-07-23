# Sample App - Terraform Module

This Terraform module deploys the GKE Marketplace Sample Application to a Google Kubernetes Engine (GKE) cluster using the Helm provider.

## Usage

```hcl
module "sample_app" {
  source = "."

  project_id         = "your-project-id"
  cluster_name       = "your-cluster-name"
  cluster_location   = "us-central1-a"
  namespace          = "sample-app"
  image_repo         = "us-docker.pkg.dev/your-project/your-repo/py-app"
  image_tag          = "1.0.0"
  helm_chart_repo    = "us-docker.pkg.dev/your-project/your-repo/chart"
  helm_chart_version = "1.0.0"
  license_key        = "your-license-key"
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_id` | The GCP project ID where the GKE cluster resides | `string` | yes |
| `cluster_name` | The name of the target GKE cluster | `string` | yes |
| `cluster_location` | The zone or region of the target GKE cluster | `string` | yes |
| `namespace` | The Kubernetes namespace for deployment | `string` | no |
| `image_repo` | The application container image repository path | `string` | yes |
| `image_tag` | The application container image tag | `string` | yes |
| `helm_chart_repo` | The Helm chart container image repository path | `string` | yes |
| `helm_chart_version` | The Helm chart container image tag | `string` | yes |
| `license_key` | The license key for the application | `string` | no |

## Outputs

| Name | Description |
|------|-------------|
| `application_namespace` | The Kubernetes namespace where the application is deployed |
| `application_name` | The Helm release name of the deployed application |
| `port_forward_command` | Command to access the application locally via port-forward |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| google | >= 5.0.0, < 7.0.0 |
| kubernetes | >= 2.0.0, < 3.0.0 |
| helm | >= 2.0.0, < 3.0.0 |
| external | >= 2.0.0, < 3.0.0 |

# --- GKE Cluster Variables ---

variable "project_id" {
  description = "The GCP project ID where the GKE cluster resides."
  type        = string
}

variable "cluster_name" {
  description = "The name of the target GKE cluster."
  type        = string
}

variable "cluster_location" {
  description = "The zone or region of the target GKE cluster."
  type        = string
}

variable "namespace" {
  description = "The Kubernetes namespace for deployment."
  type        = string
  default     = "default"
}

# --- Required by Google Cloud Marketplace ---
# Injected automatically by the Marketplace actuation engine with the
# customer-provided deployment name. Used to namespace all resource names
# and avoid collisions when the same product is deployed multiple times.

variable "goog_cm_deployment_name" {
  description = "The name of the deployment, injected by Google Cloud Marketplace."
  type        = string
  default     = "sample-app"
}

# --- Application Image Variables (mapped via schema.yaml) ---

variable "image_repo" {
  description = "The application container image repository path."
  type        = string
}

variable "image_tag" {
  description = "The application container image tag."
  type        = string
}

# --- Helm Chart Image Variables (mapped via schema.yaml) ---

variable "helm_chart_name" {
  description = "The Helm chart container image name."
  type        = string
  default     = "chart"
}

variable "helm_chart_repo" {
  description = "The Helm chart container image repository path."
  type        = string
}

variable "helm_chart_version" {
  description = "The Helm chart container image tag."
  type        = string
}

# --- Application Variables ---

variable "license_key" {
  description = "The license key for the application."
  type        = string
  default     = ""
}

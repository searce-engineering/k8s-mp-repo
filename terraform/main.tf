# --- Provider Configuration ---

provider "google" {
  project        = var.project_id
  default_labels = {}
}

data "google_client_config" "default" {}

data "google_container_cluster" "target" {
  name     = var.cluster_name
  location = var.cluster_location
  project  = var.project_id
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.target.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.target.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.target.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.target.master_auth[0].cluster_ca_certificate)
  }
}

# --- Namespace ---

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.goog_cm_deployment_name
  }
}

# --- Helm Release ---
# The chart is pulled directly from Artifact Registry as a proper OCI
# artifact. No crane extraction or external data source needed.

resource "helm_release" "sample_app" {
  name       = var.goog_cm_deployment_name
  namespace  = kubernetes_namespace.app.metadata[0].name
  repository = "oci://${var.helm_chart_repo}"
  chart      = var.helm_chart_name
  version    = var.helm_chart_version

  set {
    name  = "image.repository"
    value = var.image_repo
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "namespace"
    value = var.goog_cm_deployment_name
  }

  set {
    name  = "licenseKey"
    value = var.license_key
  }
}

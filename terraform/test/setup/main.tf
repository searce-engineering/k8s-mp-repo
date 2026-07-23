variable "activate_apis" {
  description = "List of GCP APIs to enable for this blueprint."
  type        = list(string)
  default = [
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
  ]
}

# These declarations are read by the CFT CLI to populate
# spec.requirements.services in metadata.yaml.
resource "google_project_service" "services" {
  for_each           = toset(var.activate_apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

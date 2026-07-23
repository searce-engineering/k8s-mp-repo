variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "sa_email" {
  description = "The service account email to grant roles to."
  type        = string
}

# These declarations are read by the CFT CLI to populate
# spec.requirements.roles in metadata.yaml.
resource "google_project_iam_member" "roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/artifactregistry.reader",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.sa_email}"
}

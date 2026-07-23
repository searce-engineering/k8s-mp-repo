output "application_namespace" {
  description = "The Kubernetes namespace where the application is deployed."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "application_name" {
  description = "The Helm release name of the deployed application."
  value       = helm_release.sample_app.name
}

output "port_forward_command" {
  description = "Command to access the application locally."
  value       = "kubectl port-forward svc/sample-app-svc -n ${var.goog_cm_deployment_name}-ns 8080:80"
}

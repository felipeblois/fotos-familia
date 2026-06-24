# =============================================================================
# NEVIIM — Terraform: Outputs
# =============================================================================

output "gcp_project_id" {
  description = "ID do projeto GCP usado neste deploy"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "Região GCP configurada"
  value       = var.gcp_region
}

output "environment" {
  description = "Ambiente de deploy"
  value       = var.environment
}

# Outputs de recursos — serão preenchidos no Sprint 5
# output "cloud_function_url" { ... }
# output "firebase_hosting_url" { ... }
# output "firestore_id" { ... }

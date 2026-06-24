# =============================================================================
# NEVIIM — Terraform: Configuração Principal de Infraestrutura
# Sprint 0: Estrutura base — recursos implementados no Sprint 5
# Provider: Google Cloud Platform
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.25"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.25"
    }
  }

  # Backend remoto — configurar no Sprint 5
  # backend "gcs" {
  #   bucket = "neviim-terraform-state"
  #   prefix = "terraform/state"
  # }
}

# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ---------------------------------------------------------------------------
# Habilitar APIs necessárias (Sprint 5)
# ---------------------------------------------------------------------------
resource "google_project_service" "required_apis" {
  for_each = toset([
    "firestore.googleapis.com",
    "firebase.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudlogging.googleapis.com",
    "drive.googleapis.com",
    "fcm.googleapis.com",
    "cloudbuild.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Secret Manager — credenciais da aplicação (CR03)
# Implementado no Sprint 5
# ---------------------------------------------------------------------------
# resource "google_secret_manager_secret" "service_account_key" { ... }

# ---------------------------------------------------------------------------
# Cloud Scheduler — notificação semanal (RF05)
# Implementado no Sprint 3
# ---------------------------------------------------------------------------
# resource "google_cloud_scheduler_job" "weekly_notification" { ... }

# ---------------------------------------------------------------------------
# Cloud Logging — retenção de logs (AU03, LG05)
# Implementado no Sprint 5
# ---------------------------------------------------------------------------
# resource "google_logging_project_sink" "audit_logs" { ... }

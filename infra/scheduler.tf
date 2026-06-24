# Infraestrutura complementar do Neviim.
# Este arquivo mantem os recursos opcionais de backup agendado do Firestore.

resource "google_storage_bucket" "firestore_backups" {
  name          = "${var.gcp_project_id}-firestore-backups"
  location      = "US"
  force_destroy = false
  storage_class = "NEARLINE"

  lifecycle_rule {
    condition {
      age = 28
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_cloud_scheduler_job" "firestore_backup_job" {
  name        = "weekly-firestore-backup"
  description = "Export semanal do Firestore para bucket frio"
  schedule    = "0 3 * * 0"
  time_zone   = "America/Sao_Paulo"

  http_target {
    http_method = "POST"
    uri         = "https://firestore.googleapis.com/v1/projects/${var.gcp_project_id}/databases/(default):exportDocuments"

    oauth_token {
      service_account_email = google_service_account.backup_agent.email
    }

    body = base64encode(jsonencode({
      outputUriPrefix = "gs://${google_storage_bucket.firestore_backups.name}"
    }))
  }
}

resource "google_service_account" "backup_agent" {
  account_id   = "firestore-backup-agent"
  display_name = "Cloud Scheduler Backup Agent"
}

resource "google_project_iam_member" "datastore_import_export" {
  project = var.gcp_project_id
  role    = "roles/datastore.importExportAdmin"
  member  = "serviceAccount:${google_service_account.backup_agent.email}"
}

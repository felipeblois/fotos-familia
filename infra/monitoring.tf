resource "google_monitoring_uptime_check_config" "backend_health" {
  count = var.enable_uptime_check && var.backend_uptime_url != "" ? 1 : 0

  display_name = "neviim-backend-health"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host       = replace(replace(var.backend_uptime_url, "https://", ""), "/health", "")
      project_id = var.gcp_project_id
    }
  }
}

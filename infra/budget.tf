resource "google_monitoring_notification_channel" "budget_email" {
  count = var.enable_budget_alert && var.budget_alert_email != "" ? 1 : 0

  display_name = "Neviim Budget Email"
  type         = "email"

  labels = {
    email_address = var.budget_alert_email
  }
}

resource "google_billing_budget" "monthly_budget" {
  count = var.enable_budget_alert ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "neviim-monthly-budget"

  budget_filter {
    projects = ["projects/${var.gcp_project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.8
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  dynamic "all_updates_rule" {
    for_each = length(google_monitoring_notification_channel.budget_email) > 0 ? [1] : []
    content {
      monitoring_notification_channels = [
        google_monitoring_notification_channel.budget_email[0].name
      ]
      disable_default_iam_recipients = true
    }
  }
}

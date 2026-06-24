# =============================================================================
# NEVIIM - Terraform: Variaveis de entrada
# =============================================================================

variable "gcp_project_id" {
  description = "ID do projeto Google Cloud Platform"
  type        = string
}

variable "gcp_region" {
  description = "Regiao padrao GCP"
  type        = string
  default     = "us-central1"
}

variable "firebase_project_id" {
  description = "ID do projeto Firebase"
  type        = string
}

variable "environment" {
  description = "Ambiente de deploy"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment deve ser: development, staging ou production."
  }
}

variable "admin_uid_whitelist" {
  description = "Lista de UIDs Firebase dos administradores"
  type        = list(string)
  sensitive   = true
}

variable "lgpd_contact_email" {
  description = "Email de contato para direitos LGPD"
  type        = string
}

variable "drive_folder_id" {
  description = "ID da pasta Google Drive da paroquia"
  type        = string
  sensitive   = true
}

variable "billing_account_id" {
  description = "Billing account para budget alert"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_budget_alert" {
  description = "Habilita budget alert mensal"
  type        = bool
  default     = false
}

variable "budget_amount_usd" {
  description = "Valor do budget mensal em USD"
  type        = number
  default     = 10
}

variable "budget_alert_email" {
  description = "Email para alerta de budget"
  type        = string
  default     = ""
}

variable "enable_uptime_check" {
  description = "Habilita monitoramento do health check publico"
  type        = bool
  default     = false
}

variable "backend_uptime_url" {
  description = "URL publica do backend para uptime check, incluindo https"
  type        = string
  default     = ""
}

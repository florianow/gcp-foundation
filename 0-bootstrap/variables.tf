variable "organization_id" {
  description = "GCP Organization ID (format: organizations/123456789)"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "gcp-foundation"
}

variable "location" {
  description = "Default location for resources (EU for GDPR compliance)"
  type        = string
  default     = "EU"
}

variable "logging_location" {
  description = "Location for organization-level logging buckets (must be 'global' for org-level buckets)"
  type        = string
  default     = "global"
}

variable "organization_admins" {
  description = "List of organization admin identities (format: user:email@domain.com or group:group@domain.com)"
  type        = list(string)
  default     = []
}

variable "security_admins" {
  description = "List of security admin identities for audit log access"
  type        = list(string)
  default     = []
}

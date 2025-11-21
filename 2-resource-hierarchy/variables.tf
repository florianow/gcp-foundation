variable "organization_id" {
  description = "GCP Organization ID"
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

variable "folder_viewers" {
  description = "List of identities with folder viewer role"
  type        = list(string)
  default     = []
}

variable "logging_admins" {
  description = "List of identities with logging admin role"
  type        = list(string)
  default     = []
}

variable "self_managed_lz_admins" {
  description = "List of identities with admin access to self-managed landing zone"
  type        = list(string)
  default     = []
}

variable "logging_bucket_url" {
  description = "URL of the centralized logging bucket (will be created by this module)"
  type        = string
  default     = ""
}

variable "gdpr_compliance_tag_value" {
  description = "Tag value for GDPR compliance (format: tagValues/123456789)"
  type        = string
  default     = null
}

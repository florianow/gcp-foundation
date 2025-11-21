variable "organization_id" {
  description = "GCP Organization ID (format: organizations/123456789)"
  type        = string
}

variable "audit_logs_project_id" {
  description = "Project ID where audit logs bucket is located"
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

variable "allowed_policy_member_domains" {
  description = "Allowed domains for IAM policy members (restrict who can be added to IAM)"
  type        = list(string)
  default     = []
}

variable "organization_viewers" {
  description = "List of identities with organization browser role"
  type        = list(string)
  default     = []
}

variable "security_admins" {
  description = "List of security admin identities for audit log access"
  type        = list(string)
  default     = []
}

variable "security_admin_group" {
  description = "Security admin group email"
  type        = string
  default     = "security-admins@example.com"
}

variable "security_contact_email" {
  description = "Email for security-related essential contacts"
  type        = string
}

variable "technical_contact_email" {
  description = "Email for technical essential contacts"
  type        = string
}

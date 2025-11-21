variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "management_folder_id" {
  description = "Management folder ID where networking project will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "gcp-foundation"
}

variable "network_admins" {
  description = "List of identities with network admin role"
  type        = list(string)
  default     = []
}

variable "network_viewers" {
  description = "List of identities with network viewer role"
  type        = list(string)
  default     = []
}

variable "dns_domain" {
  description = "Private DNS domain for internal resources"
  type        = string
  default     = "internal.example.com"
}

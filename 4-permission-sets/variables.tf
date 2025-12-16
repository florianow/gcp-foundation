variable "organization_id" {
  description = "GCP Organization ID (format: 123456789, without 'organizations/' prefix)"
  type        = string
}

variable "role_name_prefix" {
  description = "Prefix for all custom role IDs (e.g., 'sandbox', 'prod'). Will be prepended with a dot to role_id"
  type        = string
  default     = ""
}

variable "viewer" {
  description = "Project Viewer permission set configuration"
  type = object({
    role_id     = string
    title       = string
    description = string
  })
  default = {
    role_id     = "projectViewer"
    title       = "Project Viewer"
    description = "Read-only access to GCP project resources including monitoring and logging"
  }
}

variable "developer" {
  description = "Project Developer permission set configuration"
  type = object({
    role_id     = string
    title       = string
    description = string
  })
  default = {
    role_id     = "projectDeveloper"
    title       = "Project Developer"
    description = "Developer access for building and deploying applications without IAM, billing, or organization-level permissions"
  }
}

variable "operator" {
  description = "Project Operator permission set configuration"
  type = object({
    role_id     = string
    title       = string
    description = string
  })
  default = {
    role_id     = "projectOperator"
    title       = "Project Operator"
    description = "Operations and SRE access for running and maintaining production workloads"
  }
}

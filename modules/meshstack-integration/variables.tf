variable "project_id" {
  type        = string
  description = "ID of folder location"
}

variable "billing_account_id" {
  type        = string
  description = "ID of GCP billing account"
}

variable "platform_test_project" {
  type        = string
  description = "ID of platform test project"
}

variable "cloud_billing_export_dataset_id" {
  type        = string
  description = "ID of cloud billing export dataset"
}

variable "cloud_billing_export_table_id" {
  type        = string
  description = "ID of cloud billing export table"
}

variable "org_id" {
  type        = string
  description = "Google Cloud Organization ID"
}

variable "landing_zone_folder_ids" {
  type        = list(string)
  description = "List of Landing Zone folder IDs"
}

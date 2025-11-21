output "automation_project_id" {
  description = "Project ID for automation resources"
  value       = module.automation_project.project_id
}

output "automation_service_account_email" {
  description = "Service account email for Terraform automation"
  value       = module.automation_service_account.email
}

output "terraform_state_bucket" {
  description = "GCS bucket for Terraform state"
  value       = module.terraform_state_bucket.name
}

output "audit_logs_project_id" {
  description = "Project ID for audit logs"
  value       = module.audit_logs_project.project_id
}

output "audit_logs_bucket" {
  description = "GCS bucket for audit logs"
  value       = module.audit_logs_bucket.name
}

output "audit_logs_gcs_bucket" {
  description = "GCS bucket for audit logs storage"
  value       = module.audit_logs_bucket.name
}

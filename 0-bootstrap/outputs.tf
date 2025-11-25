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

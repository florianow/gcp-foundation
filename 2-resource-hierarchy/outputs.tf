output "root_folder_id" {
  description = "Root folder ID for landing zones"
  value       = module.root_folder.id
}

output "management_folder_id" {
  description = "Management folder ID"
  value       = module.management_folder.id
}

output "standard_lz_folder_id" {
  description = "Standard landing zone folder ID"
  value       = module.standard_lz_folder.id
}

output "self_managed_lz_folder_id" {
  description = "Self-managed landing zone folder ID"
  value       = module.self_managed_lz_folder.id
}

output "dev_folder_id" {
  description = "Dev environment folder ID"
  value       = module.dev_folder.id
}

output "staging_folder_id" {
  description = "Staging environment folder ID"
  value       = module.staging_folder.id
}

output "prod_folder_id" {
  description = "Production environment folder ID"
  value       = module.prod_folder.id
}

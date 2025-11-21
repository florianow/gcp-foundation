module "meshplatform" {
  source                          = "git::https://github.com/meshcloud/terraform-gcp-meshplatform.git"
  project_id                      = var.project_id
  billing_account_id              = var.billing_account_id
  cloud_billing_export_project_id = var.platform_test_project
  cloud_billing_export_dataset_id = var.cloud_billing_export_dataset_id
  cloud_billing_export_table_id   = var.cloud_billing_export_table_id
  org_id                          = var.org_id
  billing_org_id                  = var.org_id
  landing_zone_folder_ids         = var.landing_zone_folder_ids
  cloud_carbon_export_dataset_id  = ""
  cloud_carbon_export_project_id  = ""
}

output "meshplatform" {
  sensitive = true
  value     = module.meshplatform
}

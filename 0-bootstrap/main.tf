locals {
  prefix = var.prefix
  org_id = trimprefix(var.organization_id, "organizations/")
}

module "automation_project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.1.0"
  billing_account = var.billing_account_id
  name            = "${local.prefix}-automation"
  parent          = var.organization_id
  prefix          = null

  services = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
  ]

  iam = {
    "roles/owner" = var.organization_admins
  }
}

module "terraform_state_bucket" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.1.0"
  project_id    = module.automation_project.project_id
  name          = "${local.prefix}-tf-state"
  location      = var.location
  storage_class = "STANDARD"

  versioning = true

  iam = {
    "roles/storage.objectAdmin" = [module.automation_service_account.iam_email]
  }
}

module "automation_service_account" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.1.0"
  project_id = module.automation_project.project_id
  name       = "terraform-automation"

  iam = {
    "roles/iam.serviceAccountTokenCreator" = var.organization_admins
  }

  iam_project_roles = {
    (module.automation_project.project_id) = [
      "roles/editor"
    ]
  }
}

resource "google_organization_iam_member" "automation_sa_org_admin" {
  org_id = local.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = module.automation_service_account.iam_email
}

resource "google_organization_iam_member" "automation_sa_folder_admin" {
  org_id = local.org_id
  role   = "roles/resourcemanager.folderAdmin"
  member = module.automation_service_account.iam_email
}

resource "google_organization_iam_member" "automation_sa_project_creator" {
  org_id = local.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = module.automation_service_account.iam_email
}

resource "google_organization_iam_member" "automation_sa_org_policy_admin" {
  org_id = local.org_id
  role   = "roles/orgpolicy.policyAdmin"
  member = module.automation_service_account.iam_email
}

module "audit_logs_project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.1.0"
  billing_account = var.billing_account_id
  name            = "${local.prefix}-audit-logs"
  parent          = var.organization_id
  prefix          = null

  services = [
    "logging.googleapis.com",
    "storage.googleapis.com",
  ]

  iam = {
    "roles/viewer" = var.security_admins
  }
}

module "audit_logs_bucket" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.1.0"
  project_id    = module.audit_logs_project.project_id
  name          = "${local.prefix}-audit-logs"
  location      = var.location
  storage_class = "STANDARD"

  versioning            = true
  force_destroy         = false
  retention_policy = {
    retention_period = 2592000
    is_locked        = false
  }

  lifecycle_rules = {
    archival = {
      action = {
        type          = "SetStorageClass"
        storage_class = "ARCHIVE"
      }
      condition = {
        age = 365
      }
    }
  }
}

# Note: Organization-level Cloud Logging buckets are created automatically by GCP
# We'll configure an aggregated sink in stage 1-organization to route org logs
# to the GCS bucket created above (audit_logs_bucket)

module "root_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = var.organization_id
  name   = "${var.prefix}-landing-zones"

  iam = {
    "roles/viewer" = var.folder_viewers
  }
}

module "management_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.root_folder.id
  name   = "management"

  iam = {
    "roles/viewer" = var.folder_viewers
  }
}

module "standard_lz_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.root_folder.id
  name   = "standard-landing-zone"

  org_policies = {
    "gcp.resourceLocations" = {
      rules = [
        {
          allow = {
            values = ["in:eu-locations"]
          }
        }
      ]
    }

    "compute.restrictVpnPeerIPs" = {
      rules = [
        {
          deny = {
            all = true
          }
        }
      ]
    }

    "iam.disableServiceAccountCreation" = {
      rules = [{ enforce = true }]
    }

    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }

    "iam.disableServiceAccountKeyUpload" = {
      rules = [{ enforce = true }]
    }

    "iam.disableWorkloadIdentityClusterCreation" = {
      rules = [{ enforce = true }]
    }
  }

  logging_sinks = {
    standard-lz-logs = {
      destination = module.logging_bucket.name
      type        = "storage"
      filter      = "resource.type != \"k8s_cluster\""
    }
  }

  iam = {
    "roles/viewer" = var.folder_viewers
  }

  # tag_bindings = {
  #   compliance = var.gdpr_compliance_tag_value
  # }
}

module "self_managed_lz_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.root_folder.id
  name   = "self-managed-landing-zone"

  org_policies = {
    "gcp.resourceLocations" = {
      rules = [
        {
          allow = {
            values = ["in:eu-locations"]
          }
        }
      ]
    }
  }

  logging_sinks = {
    self-managed-lz-logs = {
      destination = module.logging_bucket.name
      type        = "storage"
      filter      = "resource.type != \"k8s_cluster\""
    }
  }

  iam = {
    "roles/viewer" = var.folder_viewers
    "roles/resourcemanager.folderEditor" = var.self_managed_lz_admins
  }

  # tag_bindings = {
  #   compliance = var.gdpr_compliance_tag_value
  # }
}

module "dev_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.standard_lz_folder.id
  name   = "dev"

  iam = {
    "roles/viewer" = var.folder_viewers
  }
}

module "staging_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.standard_lz_folder.id
  name   = "staging"

  iam = {
    "roles/viewer" = var.folder_viewers
  }
}

module "prod_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.standard_lz_folder.id
  name   = "prod"

  iam = {
    "roles/viewer" = var.folder_viewers
  }
}

module "logging_project" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.1.0"
  
  billing_account = var.billing_account_id
  parent          = module.management_folder.id
  name            = "${var.prefix}-centralized-logging"
  prefix          = null

  services = [
    "logging.googleapis.com",
    "storage.googleapis.com",
    "monitoring.googleapis.com",
  ]

  iam = {
    "roles/logging.admin" = var.logging_admins
    "roles/viewer"        = var.folder_viewers
  }
}

module "logging_bucket" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.1.0"
  project_id    = module.logging_project.project_id
  name          = "${var.prefix}-centralized-logs"
  location      = var.location
  storage_class = "STANDARD"

  versioning    = true
  force_destroy = false

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
        age = 90
      }
    }
    deletion = {
      action = {
        type = "Delete"
      }
      condition = {
        age = 2555
      }
    }
  }

  iam = {
    "roles/storage.objectViewer" = var.logging_admins
  }
}

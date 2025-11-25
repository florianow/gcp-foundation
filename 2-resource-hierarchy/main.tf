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

  iam = {
    "roles/viewer" = var.folder_viewers
  }

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

  iam = {
    "roles/viewer" = var.folder_viewers
    "roles/resourcemanager.folderEditor" = var.self_managed_lz_admins
  }

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

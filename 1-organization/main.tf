locals {
  essential_contacts_language = "en"
}

module "organization" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/organization?ref=v34.1.0"
  organization_id = var.organization_id

  org_policies = {
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }

    "iam.disableServiceAccountKeyUpload" = {
      rules = [{ enforce = true }]
    }

    "compute.requireShieldedVm" = {
      rules = [{ enforce = true }]
    }

    "compute.requireOsLogin" = {
      rules = [{ enforce = true }]
    }

    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }

    "compute.disableSerialPortAccess" = {
      rules = [{ enforce = true }]
    }

    "compute.vmExternalIpAccess" = {
      rules = [
        {
          deny = {
            all = true
          }
        }
      ]
    }

    "sql.restrictPublicIp" = {
      rules = [{ enforce = true }]
    }

    "sql.restrictAuthorizedNetworks" = {
      rules = [{ enforce = true }]
    }

    "storage.uniformBucketLevelAccess" = {
      rules = [{ enforce = true }]
    }

    "storage.publicAccessPrevention" = {
      rules = [{ enforce = true }]
    }

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

  org_policy_custom_constraints = {
    "custom.disableDefaultSA" = {
      resource_types = ["compute.googleapis.com/Instance"]
      method_types   = ["CREATE"]
      condition      = "resource.serviceAccounts.exists(sa, sa.email.endsWith('-compute@developer.gserviceaccount.com'))"
      action_type    = "DENY"
      display_name   = "Disable default Compute Engine service accounts"
      description    = "Prevents use of default Compute Engine service accounts to enforce least-privilege principle"
    }
  }

  logging_sinks = {
    audit-logs = {
      destination = module.audit_logs_bucket.id
      type        = "storage"
      filter      = <<-EOT
        logName: "/logs/cloudaudit.googleapis.com"
        OR
        protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
      EOT
    }
  }

  iam = {
    "roles/browser" = var.organization_viewers
  }

  iam_bindings_additive = {
    security_admin = {
      member = "user:${var.security_admin_group}"
      role   = "roles/iam.securityAdmin"
    }
  }
}

module "audit_logs_bucket" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.1.0"
  project_id    = var.audit_logs_project_id
  name          = "${var.prefix}-org-audit-logs"
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
        age = 365
      }
    }
  }

  iam = {
    "roles/storage.objectViewer" = var.security_admins
  }
}

module "essential_contacts" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/organization?ref=v34.1.0"
  
  organization_id = var.organization_id
  
  contacts = {
    (var.security_contact_email)   = ["SECURITY"]
    (var.technical_contact_email)  = ["TECHNICAL"]
  }
}

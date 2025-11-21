# GCP Foundation - Fabric Edition

A production-ready Google Cloud Platform foundation built with [Google Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules. This provides an enterprise-grade organization structure with security policies, centralized logging, and optional networking infrastructure - all managed as code.

## Overview

This foundation implements Google Cloud best practices for:
- **Organization structure** with landing zones for workload isolation
- **Security policies** enforcing GDPR compliance and security baselines
- **Centralized audit logging** with long-term retention
- **Infrastructure as Code** with Terraform and remote state management
- **Optional networking** with Shared VPC, Cloud NAT, and private connectivity

**Designed for**: Platform teams setting up new GCP organizations or retrofitting existing ones with infrastructure-as-code controls.

## What This Foundation Provides

### 🏗️ **Organization Structure**
Hierarchical folder structure organizing your cloud resources:

- **Automation project** for Terraform state and service accounts
- **Audit logs project** for compliance and security
- **Landing zones** with different security postures:
  - **Standard Landing Zone**: Highly restricted for production workloads (GDPR-compliant)
  - **Self-Managed Landing Zone**: Flexible for internal tools and experimentation
- **Environment segregation**: Dev, Staging, and Prod folders within standard zone
- **Management folder**: For centralized logging and networking infrastructure

### 🔒 **Security & Compliance**
13 organization policies automatically enforced:

**Compute Security**:
- ✅ Shielded VMs required (protection against rootkits)
- ✅ OS Login enforced (IAM-based SSH access)
- ✅ No VM public IPs (use Cloud NAT/IAP instead)
- ✅ Serial console access disabled
- ✅ No default networks (intentional design required)

**Data & Storage Security**:
- ✅ Cloud SQL private IPs only
- ✅ Uniform bucket-level access enforced
- ✅ Public bucket access prevented

**IAM Security**:
- ✅ Service account keys blocked (use Workload Identity)
- ✅ External key uploads blocked
- ✅ Default service accounts disabled

**Compliance**:
- ✅ EU-only resource locations (GDPR data residency)

**Logging & Monitoring**:
- ✅ Organization-wide audit logging
- ✅ 7-year log retention (30 days hot, 90 days archive)
- ✅ Essential contacts for security notifications

### 🌐 **Networking Foundation** (Optional)
Secure networking baseline when Stage 3 is deployed:

- **Shared VPC** for centralized network management
- **Cloud NAT** for internet egress without public IPs
- **Private Google Access** for accessing GCP APIs privately
- **Firewall rules** allowing only IAP, internal traffic, and health checks
- **Private DNS** zones for internal services

### 🔧 **Infrastructure as Code**
Production-ready Terraform setup:

- **Remote state** in GCS with versioning and locking
- **Service account automation** (no long-lived keys)
- **Modular architecture** (4 independent stages)
- **Google-maintained modules** from Cloud Foundation Fabric
- **Version-controlled** infrastructure

## What Gets Deployed

| Stage | Purpose | Resources Created | Approx. Time |
|-------|---------|-------------------|--------------|
| **Stage 0: Bootstrap** | Automation infrastructure | Automation project, audit logs project, state bucket, service accounts | 2-3 min |
| **Stage 1: Organization** | Security policies | 13 org policies, 1 custom constraint, org logging sink, essential contacts | 1-2 min |
| **Stage 2: Hierarchy** | Landing zones & folders | Root folder, 2 landing zones, 3 environment folders, centralized logging project, logging sinks | 3-5 min |
| **Stage 3: Networking** | Network foundation (optional) | Networking project, Shared VPC, subnets, Cloud NAT, firewall rules, DNS zones | 5-10 min |

**Total deployment time**: 10-20 minutes (stages 0-2) or 15-30 minutes (all stages)

## Architecture

The foundation creates a hierarchical structure within your GCP organization:

```
Organization (your-org-id)
│
├── Projects (created by bootstrap)
│   ├── {prefix}-automation          # Terraform state & service accounts
│   └── {prefix}-audit-logs          # Organization audit logs
│
└── Folders (created by hierarchy)
    └── {prefix}-landing-zones/
        │
        ├── management/
        │   ├── {prefix}-centralized-logging (project)
        │   └── {prefix}-centralized-logs (GCS bucket)
        │   └── {prefix}-networking (project) [if Stage 3]
        │
        ├── standard-landing-zone/ [RESTRICTED - Production]
        │   ├── Policies: EU-only, no SA keys, no public IPs
        │   ├── dev/ (folder)
        │   ├── staging/ (folder)
        │   └── prod/ (folder)
        │
        └── self-managed-landing-zone/ [FLEXIBLE - Internal]
            └── Policies: EU-only (minimal restrictions)
```

## Use Cases

**Ideal for**:
- ✅ **New GCP organizations** needing production-ready foundation from day 1
- ✅ **Platform engineering teams** building internal cloud platforms
- ✅ **GDPR-regulated companies** requiring EU data residency
- ✅ **Multi-environment workloads** (Dev/Staging/Prod segregation)
- ✅ **Organizations adopting IaC** for compliance and governance
- ✅ **Meshstack/cloud management platforms** requiring structured landing zones

**Not ideal for**:
- ❌ Single project/simple workloads (over-engineered)
- ❌ Non-European companies (policies enforce EU-only locations)
- ❌ Organizations requiring extreme customization (use custom setup instead)

## Landing Zones Explained

This foundation provides **two landing zones** with different security postures to support different use cases:

### 🔒 Standard Landing Zone (High Security)

**Purpose**: Production workloads requiring strict compliance

**Security Controls**:
- EU-only resource locations (GDPR compliance)
- No VPN connections allowed (forces Cloud Interconnect for hybrid)
- Service account creation disabled
- Service account keys blocked
- Workload Identity cluster creation disabled

**Structure**: Includes Dev, Staging, and Prod environment folders

**Best for**: Customer-facing applications, regulated workloads (finance, healthcare), production systems handling PII

### 🔓 Self-Managed Landing Zone (Flexibility)

**Purpose**: Internal tools and experimentation with team autonomy

**Security Controls**:
- EU-only resource locations (minimal baseline)
- Service account creation allowed
- VPN connections allowed
- More team flexibility

**Structure**: Flat structure, teams manage their own organization

**Best for**: Internal development tools, sandboxes, testing environments, experienced cloud teams

## Directory Structure

The foundation is organized into 4 independent Terraform stages:

```
gcp-foundation-fabric/
│
├── 0-bootstrap/              # Stage 0: Automation infrastructure
│   ├── main.tf              # GCS state backend, service accounts
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── 1-organization/          # Stage 1: Organization policies & logging
│   ├── main.tf              # Security policies, essential contacts
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── 2-resource-hierarchy/    # Stage 2: Landing zones & folder structure
│   ├── main.tf              # Folders with policies & logging sinks
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── 3-networking/            # Stage 3: Network foundation (optional)
│   ├── main.tf              # Shared VPC, NAT, firewall, DNS
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── modules/
│   └── meshstack-integration/  # Optional: Meshstack platform integration
│
├── README.md                     # This file (what & why)
├── GETTING_STARTED.md            # Step-by-step deployment guide (how)
└── GETTING_STARTED_BROWNFIELD.md # Existing organization deployment strategies
```

Each stage:
- **Runs independently** with its own state file
- **Outputs values** consumed by later stages
- **Can be updated** without affecting other stages
- **Uses Fabric modules** for consistent implementation

## Key Features in Detail

### Organization Policies

**Applied Organization-Wide**:
| Policy | Purpose | Impact |
|--------|---------|--------|
| `compute.requireShieldedVm` | Protects against rootkits/bootkits | All VMs must use Shielded VM features |
| `compute.requireOsLogin` | Centralized SSH management via IAM | No manual SSH key management |
| `compute.skipDefaultNetworkCreation` | Intentional network design | Projects don't get auto-created default network |
| `compute.disableSerialPortAccess` | Prevents low-level console access | Serial port disabled for security |
| `compute.vmExternalIpAccess` | Prevents direct internet exposure | VMs cannot have public IPs |
| `sql.restrictPublicIp` | Forces private database access | Cloud SQL must use private IPs |
| `sql.restrictAuthorizedNetworks` | Limits DB network access | Restricts SQL connectivity |
| `storage.uniformBucketLevelAccess` | Simplifies IAM | Bucket-level IAM only (no ACLs) |
| `storage.publicAccessPrevention` | Prevents data leaks | Buckets cannot be made public |
| `iam.disableServiceAccountKeyCreation` | Prevents long-lived credentials | Forces short-lived tokens/Workload Identity |
| `iam.disableServiceAccountKeyUpload` | Prevents key compromise | External keys cannot be uploaded |
| `gcp.resourceLocations` | GDPR data residency | All resources must be in EU |

**Custom Constraints**:
| Constraint | Resource Type | Purpose |
|------------|---------------|---------|
| `custom.disableDefaultSA` | Compute Instances | Prevents use of default Compute Engine service account (least-privilege) |

**Standard Landing Zone Additional Policies**:
- No VPN creation (forces Cloud Interconnect for hybrid connectivity)
- No service account creation (centralized IAM management)
- No Workload Identity cluster creation in non-standard environments

### Centralized Logging Architecture

**Organization Level**:
- Cloud Logging bucket: 30-day retention in Cloud Logging
- All organization audit logs captured
- Sink configured automatically

**Landing Zone Level**:
- Dedicated GCS bucket per landing zone
- **Lifecycle management**:
  - Day 1-30: STANDARD storage class (hot access)
  - Day 31-90: ARCHIVE storage class (compliance retention)
  - Day 2557+: Auto-deletion (7-year retention complete)
- **Filters**: Excludes k8s_cluster logs (too verbose, stored separately)
- **Compliance**: Meets most regulatory requirements (GDPR, SOC2, HIPAA)

## Getting Started

### Choose Your Deployment Type

- **Greenfield (New Organization)**: Follow [GETTING_STARTED.md](GETTING_STARTED.md) - Complete step-by-step guide for brand new GCP organizations
- **Brownfield (Existing Organization)**: Follow [GETTING_STARTED_BROWNFIELD.md](GETTING_STARTED_BROWNFIELD.md) - Strategies for deploying alongside existing resources

### Quick Start (Greenfield)

### Step 0: Bootstrap (State Backend & Automation)

```bash
cd 0-bootstrap

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set: organization_id, billing_account_id, prefix

# Initialize and apply
terraform init
terraform plan
terraform apply

# Note the outputs - you'll need them for next stages
terraform output
```

**Important Outputs:**
- `terraform_state_bucket` - Use this in backend.tf for other stages
- `automation_service_account_email` - Service account for automation
- `audit_logs_project_id` - Project for centralized audit logs

### Step 1: Organization Policies

```bash
cd ../1-organization

# Update backend.tf with your state bucket name from step 0
vim backend.tf  # Replace REPLACE_WITH_STATE_BUCKET_NAME

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Set required values:
# - organization_id (same as step 0)
# - audit_logs_project_id (from step 0 output)
# - allowed_policy_member_domains (your organization's domain)
# - security_contact_email
# - technical_contact_email

terraform init
terraform plan
terraform apply
```

### Step 2: Resource Hierarchy (Folders & Landing Zones)

```bash
cd ../2-resource-hierarchy

# Update backend.tf with your state bucket name
vim backend.tf  # Replace REPLACE_WITH_STATE_BUCKET_NAME

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

terraform init
terraform plan
terraform apply

# Note the folder IDs for landing zones
terraform output
```

### Step 3: Networking Foundation

```bash
cd ../3-networking

# Update backend.tf with your state bucket name
vim backend.tf  # Replace REPLACE_WITH_STATE_BUCKET_NAME

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Set:
# - management_folder_id (from step 2 output)
# - dns_domain (your internal domain)

terraform init
terraform plan
terraform apply
```

## Key Features Explained

### Organization Policies (EU GDPR Compliance)

Applied at **organization level**:
- ✅ Require Shielded VMs
- ✅ Require OS Login
- ✅ Skip default network creation
- ✅ Disable serial port access
- ✅ Restrict Cloud SQL to private IPs only
- ✅ Enforce uniform bucket-level access

Applied to **Standard Landing Zone** only:
- ✅ EU-only resource locations (`in:eu-locations`)
- ✅ Disable VPN (force on-prem via Interconnect/Partner)
- ✅ Disable service account creation
- ✅ Disable service account key management
- ✅ Disable Workload Identity cluster creation

### Centralized Logging

**Organization-level:**
- Cloud Logging bucket (30-day retention)
- All audit logs captured

**Landing Zone level:**
- GCS bucket for each LZ
- 30-day hot storage
- 90-day archive to ARCHIVE class
- 7-year total retention
- Auto-deletion after retention

### Networking Security Baseline

**Firewall Rules:**
- ✅ Allow IAP for SSH (35.235.240.0/20)
- ✅ Allow internal traffic (10.0.0.0/8)
- ✅ Allow health checks (GCP ranges)
- ✅ Allow Google APIs via Private Google Access
- ❌ **Deny all other egress by default**

**Private DNS:**
- Internal zone for your domain
- Private googleapis.com zone (VPC endpoints)

**Cloud NAT:**
- Secure egress without public IPs
- EU region (europe-west1)

## Important Security Notes

### Break-Glass Access

The bootstrap stage creates an automation service account with org admin rights. For break-glass scenarios:

1. Add your admin group to `organization_admins` in `0-bootstrap/terraform.tfvars`
2. Create a dedicated break-glass user account (not part of normal SSO)
3. Store credentials securely (vault, HSM)

### Service Account Impersonation

Instead of using service account keys, use impersonation:

```bash
# Impersonate the automation SA
gcloud config set auth/impersonate_service_account \
  SERVICE_ACCOUNT_EMAIL_FROM_BOOTSTRAP_OUTPUT

# Run terraform
terraform plan
terraform apply

# Stop impersonation
gcloud config unset auth/impersonate_service_account
```

### Shared VPC Attachment

To attach projects to the Shared VPC:

```hcl
module "my_project" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.1.0"
  
  name            = "my-project"
  parent          = var.dev_folder_id
  billing_account = var.billing_account_id
  
  shared_vpc_service_config = {
    host_project       = var.networking_project_id
    service_identity_iam = {
      "roles/compute.networkUser" = ["cloudservices", "container-engine"]
    }
  }
  
  services = ["compute.googleapis.com"]
}
```

## Meshstack Integration (Optional)

If you're using Meshstack for multi-cloud management:

```hcl
module "meshstack" {
  source = "./modules/meshstack-integration"
  
  org_id                          = var.organization_id
  billing_account_id              = var.billing_account_id
  project_id                      = "meshstack-integration-project"
  platform_test_project           = "platform-test-project"
  cloud_billing_export_dataset_id = "billing_export"
  cloud_billing_export_table_id   = "gcp_billing_export"
  
  landing_zone_folder_ids = [
    module.standard_lz_folder.id,
    module.self_managed_lz_folder.id
  ]
}
```

## Comparison: Old vs New

| Feature | Your Old Setup | New Fabric Setup |
|---------|---------------|------------------|
| **Modules** | Custom modules | Fabric modules (maintained by Google) |
| **Lines of code** | ~200 | ~150 (more features, less code) |
| **State backend** | ❌ Local | ✅ GCS with versioning |
| **Org policies** | ✅ Basic | ✅ Comprehensive + custom constraints |
| **Logging** | ✅ Folder-level | ✅ Org + folder-level |
| **Networking** | ❌ Not included | ✅ Shared VPC + NAT + firewall |
| **IAM management** | ❌ Manual | ✅ Built into modules |
| **Environment split** | ❌ No | ✅ Dev/Staging/Prod |
| **Essential contacts** | ❌ No | ✅ Yes |
| **Meshstack** | ✅ Yes | ✅ Yes (preserved) |

## What's Important from Day 1

### Must-Have (Included)
1. ✅ **State backend** - GCS with versioning
2. ✅ **Audit logging** - Organization-wide with retention
3. ✅ **Org policies** - GDPR compliance (EU-only resources)
4. ✅ **Folder structure** - Environment segregation
5. ✅ **IAM baseline** - Least privilege, group-based

### Should-Have (Included)
6. ✅ **Networking** - Shared VPC for centralized control
7. ✅ **Cloud NAT** - No public IPs on VMs
8. ✅ **Private Google Access** - VPC endpoints
9. ✅ **Essential contacts** - Security notifications
10. ✅ **Logging retention** - 7 years for compliance

### Nice-to-Have (Not Included, Add Later)
- CI/CD integration (Cloud Build, GitHub Actions)
- VPN or Cloud Interconnect for on-prem
- Security Command Center
- Binary Authorization
- Workload Identity Federation
- Budget alerts
- Custom dashboards

## Maintenance

### Updating Fabric Modules

All modules reference `?ref=v34.1.0`. To update:

1. Check [Fabric releases](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/releases)
2. Update version in all modules
3. Run `terraform init -upgrade`
4. Test in dev environment first

### Adding New Landing Zones

Edit `2-resource-hierarchy/main.tf`:

```hcl
module "custom_lz_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = module.root_folder.id
  name   = "custom-landing-zone"
  
  org_policies = {
    # Your policies here
  }
  
  logging_sinks = {
    custom-lz-logs = {
      destination = var.logging_bucket_url
      type        = "storage"
    }
  }
}
```

## Troubleshooting

### "Permission denied" errors

Run with service account impersonation:
```bash
gcloud config set auth/impersonate_service_account SA_EMAIL
```

### Org policy violations

Check current policies:
```bash
gcloud org-policies list --organization=ORG_ID
gcloud org-policies describe CONSTRAINT_NAME --organization=ORG_ID
```

### Logging sink not working

1. Check sink writer identity has storage.objectCreator role
2. Verify bucket exists in correct location
3. Check log filter syntax

## Support

- **Fabric Documentation**: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric
- **Fabric Modules**: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules
- **GCP Best Practices**: https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations

## License

Apache 2.0 (same as Google Cloud Foundation Fabric)

# Getting Started - Greenfield GCP Organization

> **Note**: This guide is for **greenfield** (brand new) GCP organizations. If your organization already has existing folders, projects, or policies, see [GETTING_STARTED_BROWNFIELD.md](GETTING_STARTED_BROWNFIELD.md) instead.

## Before You Start

You need:
1. ✅ A brand new GCP Organization (created via Google Workspace or Cloud Identity)
2. ✅ Organization Admin role
3. ✅ A Billing Account linked to the organization
4. ✅ gcloud CLI installed

## Greenfield vs Brownfield

- **Greenfield**: Your GCP organization is brand new with no existing resources → Use this guide
- **Brownfield**: Your organization already has existing folders, projects, policies, or workloads → Use [GETTING_STARTED_BROWNFIELD.md](GETTING_STARTED_BROWNFIELD.md)

## Step-by-Step Setup

### 1. Login to Google Cloud Shell (or local terminal)

```bash
# Login with your admin account
gcloud auth login

# List your organizations
gcloud organizations list

# Set your organization ID
export ORG_ID="123456789012"  # Replace with your org ID
export ORG_NAME="organizations/${ORG_ID}"

# List billing accounts
gcloud billing accounts list

# Set your billing account
export BILLING_ACCOUNT="ABCDEF-123456-ABCDEF"  # Replace with your billing account ID
```

### 2. Verify Permissions

```bash
# Check you have org admin role
gcloud organizations get-iam-policy ${ORG_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/resourcemanager.organizationAdmin"

# You should see your email in the output
```

### 3. Enable Required APIs (at Org Level)

```bash
# Create a temporary bootstrap project (we'll use this to enable APIs)
gcloud projects create temp-bootstrap-$(date +%s) \
  --organization=${ORG_ID} \
  --set-as-default

export TEMP_PROJECT=$(gcloud config get-value project)

# Link billing account
gcloud billing projects link ${TEMP_PROJECT} \
  --billing-account=${BILLING_ACCOUNT}

# Enable required APIs
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  --project=${TEMP_PROJECT}
```

### 4. Configure Application Default Credentials

```bash
# IMPORTANT: Terraform requires Application Default Credentials to work properly
# This refreshes your credentials with current IAM permissions
gcloud auth application-default login

# Follow the browser prompts to authenticate
```

### 5. Clone/Download This Repository

```bash
# If in Cloud Shell, upload the gcp-foundation-fabric folder
# Or clone if you have it in a git repo

cd 0-bootstrap
```

### 6. Configure Bootstrap Stage

```bash
# Create your terraform.tfvars file
cat > terraform.tfvars <<EOF
organization_id     = "${ORG_NAME}"
billing_account_id  = "${BILLING_ACCOUNT}"
prefix              = "my-org"  # Change this to your org name
location            = "EU"

organization_admins = [
  "user:your-admin@example.com",  # Change this
  "group:gcp-admins@example.com"  # Optional: create a group first
]

security_admins = [
  "group:security-team@example.com"  # Optional
]
EOF

# Review the file
cat terraform.tfvars
```

### 7. Run Bootstrap

```bash
# Initialize Terraform (first time only)
terraform init

# Preview what will be created
terraform plan

# Review the plan carefully, then apply
terraform apply

# Save important outputs
terraform output -json > ../bootstrap-outputs.json

# Save the state bucket name (you'll need this!)
export STATE_BUCKET=$(terraform output -raw terraform_state_bucket)
echo "State bucket: ${STATE_BUCKET}"

# Migrate bootstrap state to the GCS bucket
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/0-bootstrap"
  }
}
EOF

# Reinitialize to migrate state
terraform init -migrate-state

# Verify state is in GCS
gsutil ls gs://${STATE_BUCKET}/terraform/state/0-bootstrap/
```

### 8. Configure Organization Stage

```bash
cd ../1-organization

# Update backend.tf with your state bucket
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/1-organization"
  }
}
EOF

# Set variables
export ADMIN_EMAIL="your-admin@example.com"  # Change this to your email
export PREFIX="my-org"  # Change this to your prefix

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
organization_id    = "${ORG_NAME}"
billing_account_id = "${BILLING_ACCOUNT}"
prefix             = "${PREFIX}"
location           = "EU"

organization_viewers = ["user:${ADMIN_EMAIL}"]
security_admins      = ["user:${ADMIN_EMAIL}"]
security_admin_group     = "${ADMIN_EMAIL}"
security_contact_email   = "${ADMIN_EMAIL}"
technical_contact_email  = "${ADMIN_EMAIL}"

allowed_policy_member_domains = []
EOF

# REQUIRED CODE FIX: Comment out iam.allowedPolicyMemberDomains policy
# This prevents "empty list" error
sed -i.bak '/^[[:space:]]*"iam.allowedPolicyMemberDomains"/,/^[[:space:]]*# }$/s/^/# /' main.tf

# Alternative: Manual edit
# Edit main.tf and comment out lines 10-18 (the entire iam.allowedPolicyMemberDomains block)

# REQUIRED: Create provider.tf to set quota project for APIs
cat > provider.tf <<EOF
provider "google" {
  billing_project       = "${PREFIX}-automation"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "${PREFIX}-automation"
  user_project_override = true
}
EOF

# REQUIRED: Enable APIs in automation project
gcloud services enable logging.googleapis.com essentialcontacts.googleapis.com orgpolicy.googleapis.com --project=${PREFIX}-automation

# REQUIRED: Set quota project for Application Default Credentials
gcloud auth application-default set-quota-project ${PREFIX}-automation

# Initialize and import existing policy
terraform init

# Import pre-existing storage.uniformBucketLevelAccess policy (if it exists)
terraform import 'module.organization.google_org_policy_policy.default["storage.uniformBucketLevelAccess"]' ${ORG_NAME}/policies/storage.uniformBucketLevelAccess

# Apply
terraform plan
terraform apply
```

### 9. Configure Resource Hierarchy

```bash
cd ../2-resource-hierarchy

# Update backend.tf
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/2-resource-hierarchy"
  }
}
EOF

# REQUIRED: Create provider.tf with billing project configuration
cat > provider.tf <<EOF
provider "google" {
  billing_project       = "${PREFIX}-automation"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "${PREFIX}-automation"
  user_project_override = true
}
EOF

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
organization_id    = "${ORG_NAME}"
billing_account_id = "${BILLING_ACCOUNT}"
prefix             = "${PREFIX}"
location           = "EU"

folder_viewers = ["user:${ADMIN_EMAIL}"]
self_managed_lz_admins = ["user:${ADMIN_EMAIL}"]
EOF

# Set environment variables (CRITICAL)
export GOOGLE_CLOUD_QUOTA_PROJECT="${PREFIX}-automation"
gcloud config set project ${PREFIX}-automation

# Grant required permissions
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${ADMIN_EMAIL}" \
  --role="roles/resourcemanager.folderAdmin"

# Enable Cloud Billing API
gcloud services enable cloudbilling.googleapis.com --project=${PREFIX}-automation

# Initialize and apply
terraform init
terraform plan
terraform apply

# Save outputs
terraform output -json > ../hierarchy-outputs.json
export MGMT_FOLDER=$(terraform output -raw management_folder_id)
```

### 10. Configure Networking

```bash
cd ../3-networking

# Update backend.tf
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/3-networking"
  }
}
EOF

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
billing_account_id   = "${BILLING_ACCOUNT}"
management_folder_id = "${MGMT_FOLDER}"
prefix               = "my-org"

network_admins = [
  "group:network-admins@example.com"
]

network_viewers = [
  "group:platform-viewers@example.com"
]

dns_domain = "internal.example.com"
EOF

terraform init
terraform plan
terraform apply
```

### 11. Clean Up Temporary Project

```bash
# Delete the temporary bootstrap project
gcloud projects delete ${TEMP_PROJECT}
```

## Security Policies Applied

The foundation automatically deploys **13 organization-level security policies** to protect your GCP organization:

### Standard Organization Policies (10)

| Policy | Purpose | Impact |
|--------|---------|--------|
| `compute.requireShieldedVm` | Requires Shielded VMs for all Compute instances | Protects against rootkits and bootkits |
| `compute.requireOsLogin` | Requires OS Login for SSH access | Centralizes SSH key management via IAM |
| `compute.skipDefaultNetworkCreation` | Prevents auto-creation of default networks | Forces intentional network design |
| `compute.disableSerialPortAccess` | Blocks serial console access | Prevents unauthorized low-level access |
| `compute.vmExternalIpAccess` | Denies public IPs on VMs | Prevents direct internet exposure |
| `sql.restrictPublicIp` | Prevents Cloud SQL public IPs | Forces private database access |
| `sql.restrictAuthorizedNetworks` | Restricts SQL authorized networks | Limits database network access |
| `storage.uniformBucketLevelAccess` | Enforces uniform bucket-level IAM | Simplifies access control |
| `storage.publicAccessPrevention` | Prevents public bucket access | Protects against data leaks |
| `iam.disableServiceAccountKeyCreation` | Blocks service account key creation | Prevents long-lived credentials |
| `iam.disableServiceAccountKeyUpload` | Blocks external key uploads | Prevents key compromise |
| `gcp.resourceLocations` | Restricts resources to EU locations only | GDPR/data residency compliance |

### Custom Constraints (1)

| Constraint | Resource Type | Purpose |
|------------|---------------|---------|
| `custom.disableDefaultSA` | Compute Instances | Prevents use of default Compute Engine service accounts (least-privilege) |

### Essential Contacts

Security and technical contacts configured to receive:
- Security notifications (breaches, vulnerabilities)
- Technical alerts (outages, maintenance)

### Verifying Applied Policies

```bash
# List all organization policies
gcloud org-policies list --organization=YOUR_ORG_ID

# Check a specific policy
gcloud org-policies describe POLICY_NAME --organization=YOUR_ORG_ID

# List custom constraints
gcloud org-policies list-custom-constraints --organization=YOUR_ORG_ID
```

### Important Notes

⚠️ **These policies will block certain operations**:
- Cannot create VMs with public IPs (use Cloud NAT or IAP instead)
- Cannot create Cloud SQL instances with public IPs
- Cannot use default service accounts
- All resources must be in European locations

💡 **If you need to temporarily bypass a policy** for specific projects:
```bash
# Example: Allow external IPs for a specific project
gcloud org-policies set-policy policy.yaml --project=PROJECT_ID
```

See the [Troubleshooting](#troubleshooting---issues-encountered-during-real-deployment) section if you encounter policy-related errors.

## Post-Deployment Checklist

- [ ] Verify all projects were created
- [ ] Check org policies are applied (`gcloud org-policies list`)
- [ ] Verify logging sinks are working
- [ ] Test Shared VPC connectivity
- [ ] Set up Cloud Identity groups (if not done)
- [ ] Configure billing budgets and alerts
- [ ] Review security policies and adjust if needed
- [ ] Enable Security Command Center (optional)
- [ ] Set up CI/CD for Terraform (optional)

## Common Issues

### "failed pre-requisites: missing permission on billingAccounts"
- Run `gcloud auth application-default login` to refresh Application Default Credentials
- This updates Terraform's credentials with your current IAM permissions
- Always run this before starting the bootstrap stage

### "Organization policy constraint violated"
- Run `gcloud org-policies reset CONSTRAINT --organization=${ORG_ID}`
- Some constraints may be set by default in new orgs

### "Billing not enabled"
- Verify billing account is linked: `gcloud billing projects describe PROJECT_ID`
- Link manually: `gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT`

### "Permission denied"
- Verify you have org admin role
- Some operations may need billing account admin role too

### "API not enabled"
- Enable at org level: `gcloud services enable API_NAME --project=PROJECT_ID`

## Troubleshooting - Issues Encountered During Real Deployment

### Stage 1: Organization

#### Issue 1: Custom constraints can only have one resource type
**Error**: `Custom constraint has to be associated with only one resource type`

**Root Cause**: GCP organization policy custom constraints do not support multiple resource types in a single constraint.

**Fix**: Split multi-resource-type constraints into separate constraints per resource type. This has been fixed in the code.

**What was changed**:
- Removed: Single `custom.requireEuLocations` constraint with 4 resource types
- Instead: Using standard policy `gcp.resourceLocations` with value `in:eu-locations`

#### Issue 2: Custom constraint location field doesn't exist
**Error**: `undefined field 'location'` in custom constraint condition

**Root Cause**: Custom constraints use CEL (Common Expression Language) which doesn't expose `resource.location` for all resource types. Each resource type has different available fields.

**Fix**: Use the standard `gcp.resourceLocations` organization policy instead of custom constraints for location restrictions:
```hcl
"gcp.resourceLocations" = {
  rules = [
    {
      allow = {
        values = ["in:eu-locations"]
      }
    }
  ]
}
```

#### Issue 3: Pre-existing IAM service account policies
**Error**: `Error 409: Requested entity already exists` for `iam.disableServiceAccountKeyCreation` and `iam.disableServiceAccountKeyUpload`

**Root Cause**: These policies may have been created during previous partial applies.

**Fix**: Import the existing policies:
```bash
cd 1-organization
terraform import 'module.organization.google_org_policy_policy.default["iam.disableServiceAccountKeyCreation"]' organizations/YOUR_ORG_ID/policies/iam.disableServiceAccountKeyCreation
terraform import 'module.organization.google_org_policy_policy.default["iam.disableServiceAccountKeyUpload"]' organizations/YOUR_ORG_ID/policies/iam.disableServiceAccountKeyUpload
terraform apply
```

#### Issue 4: Invalid domain format for allowed policy members
**Error**: `Invalid value: [gmail.com]` for `iam.allowedPolicyMemberDomains`

**Root Cause**: This policy requires Cloud Identity Customer ID (format: `C0xxxxxxx`), not domain names.

**Fix**: This policy is now commented out in the code. To use it, you need:
1. Set up Cloud Identity or Google Workspace
2. Get your Customer ID: `gcloud organizations describe YOUR_ORG_ID --format="value(owner.directoryCustomerId)"`
3. Use format: `["C01234567"]` not `["gmail.com"]`

#### Issue 5: Pre-existing storage.uniformBucketLevelAccess policy
**Error**: Policy already exists at organization level

**Fix**: Import the existing policy before applying:
```bash
cd 1-organization
terraform import 'module.organization.google_org_policy_policy.default["storage.uniformBucketLevelAccess"]' organizations/YOUR_ORG_ID/policies/storage.uniformBucketLevelAccess
terraform apply
```

### Stage 2: Resource Hierarchy

#### Issue 1: Billing quota project not set
**Error**: `failed pre-requisites: [missing permission on billingAccounts/...]`

**Fix**: Create `2-resource-hierarchy/provider.tf`:
```hcl
provider "google" {
  billing_project       = "YOUR_PREFIX-automation"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "YOUR_PREFIX-automation"
  user_project_override = true
}
```

#### Issue 2: Missing folder creation permissions
**Error**: `Error creating Folder: googleapi: Error 403: Permission 'resourcemanager.folders.create' denied`

**Fix**: Grant yourself folderAdmin role:
```bash
gcloud organizations add-iam-policy-binding YOUR_ORG_ID \
  --member="user:your-admin@example.com" \
  --role="roles/resourcemanager.folderAdmin"
```

#### Issue 3: Cloud Billing API not enabled
**Error**: `Cloud Billing API has not been used in project`

**Fix**: Enable the API in the automation project:
```bash
gcloud services enable cloudbilling.googleapis.com --project=YOUR_PREFIX-automation
```

#### Issue 4: Tag bindings without tags configured
**Error**: Tags referenced but not created

**Fix**: This has been removed from the code. No action needed.

#### Issue 5: Logging sink destination format incorrect
**Error**: `Bucket storage.googleapis.com does not exist`

**Fix**: This has been removed from the code. Stage 2 no longer creates logging sinks. Teams manage their own logging.

### Environment Setup

**CRITICAL**: Set these environment variables before running any terraform commands in stage 2+:
```bash
export GOOGLE_CLOUD_QUOTA_PROJECT=YOUR_PREFIX-automation
gcloud config set project YOUR_PREFIX-automation
```

## Actual Working Configuration Files

### Stage 1: terraform.tfvars
```hcl
organization_id    = "organizations/123456789012"
billing_account_id = "ABCDEF-123456-ABCDEF"
prefix             = "my-org"
location           = "EU"

audit_logs_project_id = "my-org-audit-logs"

organization_viewers = ["user:admin@example.com"]
security_admins      = ["user:admin@example.com"]
security_admin_group     = "admin@example.com"
security_contact_email   = "admin@example.com"
technical_contact_email  = "admin@example.com"

allowed_policy_member_domains = []
```

### Stage 1: backend.tf
```hcl
terraform {
  backend "gcs" {
    bucket = "my-org-tf-state"
    prefix = "terraform/state/1-organization"
  }
}
```

### Stage 2: terraform.tfvars
```hcl
organization_id    = "organizations/123456789012"
billing_account_id = "ABCDEF-123456-ABCDEF"
prefix             = "my-org"
location           = "EU"

folder_viewers = ["user:admin@example.com"]
self_managed_lz_admins = ["user:admin@example.com"]
```

### Stage 2: backend.tf
```hcl
terraform {
  backend "gcs" {
    bucket = "my-org-tf-state"
    prefix = "terraform/state/2-resource-hierarchy"
  }
}
```

### Stage 2: provider.tf
```hcl
provider "google" {
  billing_project       = "my-org-automation"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "my-org-automation"
  user_project_override = true
}
```

## Complete Deployment Sequence

Here's the exact sequence that worked (adjust ORG_ID, BILLING_ACCOUNT, PREFIX, and ADMIN_EMAIL to your values):

### Prerequisites
```bash
# Set your variables
export ORG_ID="123456789012"
export ORG_NAME="organizations/${ORG_ID}"
export BILLING_ACCOUNT="ABCDEF-123456-ABCDEF"
export PREFIX="my-org"
export ADMIN_EMAIL="admin@example.com"
export STATE_BUCKET="${PREFIX}-tf-state"
export AUTOMATION_PROJECT="${PREFIX}-automation"

# Authenticate
gcloud auth application-default login
```

### Stage 0: Bootstrap (Assumes automation project exists)
If you don't have an automation project yet, create it first using the bootstrap stage in sections 6-7 above.

### Stage 1: Organization
```bash
cd 1-organization

# Create backend.tf
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/1-organization"
  }
}
EOF

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
organization_id    = "${ORG_NAME}"
billing_account_id = "${BILLING_ACCOUNT}"
prefix             = "${PREFIX}"
location           = "EU"

audit_logs_project_id = "${PREFIX}-audit-logs"

organization_viewers = ["user:${ADMIN_EMAIL}"]
security_admins      = ["user:${ADMIN_EMAIL}"]
security_admin_group     = "${ADMIN_EMAIL}"
security_contact_email   = "${ADMIN_EMAIL}"
technical_contact_email  = "${ADMIN_EMAIL}"

allowed_policy_member_domains = []
EOF

# REQUIRED: Comment out iam.allowedPolicyMemberDomains in main.tf
# Edit main.tf and comment out lines 10-18 (the entire iam.allowedPolicyMemberDomains block)
# Or use sed (macOS):
# sed -i.bak '10,18s/^/# /' main.tf

# REQUIRED: Create provider.tf to set quota project for APIs
cat > provider.tf <<EOF
provider "google" {
  billing_project       = "${AUTOMATION_PROJECT}"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "${AUTOMATION_PROJECT}"
  user_project_override = true
}
EOF

# REQUIRED: Enable APIs in automation project
gcloud services enable logging.googleapis.com essentialcontacts.googleapis.com orgpolicy.googleapis.com --project=${AUTOMATION_PROJECT}

# REQUIRED: Set quota project for Application Default Credentials
gcloud auth application-default set-quota-project ${AUTOMATION_PROJECT}

# Initialize and import existing policy
terraform init
terraform import 'module.organization.google_org_policy_policy.default["storage.uniformBucketLevelAccess"]' ${ORG_NAME}/policies/storage.uniformBucketLevelAccess

# Deploy
terraform plan
terraform apply
```

### Stage 2: Resource Hierarchy
```bash
cd ../2-resource-hierarchy

# Create backend.tf
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state/2-resource-hierarchy"
  }
}
EOF

# Create provider.tf (REQUIRED)
cat > provider.tf <<EOF
provider "google" {
  billing_project       = "${AUTOMATION_PROJECT}"
  user_project_override = true
}

provider "google-beta" {
  billing_project       = "${AUTOMATION_PROJECT}"
  user_project_override = true
}
EOF

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
organization_id    = "${ORG_NAME}"
billing_account_id = "${BILLING_ACCOUNT}"
prefix             = "${PREFIX}"
location           = "EU"

folder_viewers = ["user:${ADMIN_EMAIL}"]
self_managed_lz_admins = ["user:${ADMIN_EMAIL}"]
EOF

# Set environment (CRITICAL)
export GOOGLE_CLOUD_QUOTA_PROJECT="${AUTOMATION_PROJECT}"
gcloud config set project ${AUTOMATION_PROJECT}

# Grant permissions
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${ADMIN_EMAIL}" \
  --role="roles/resourcemanager.folderAdmin"

# Enable API
gcloud services enable cloudbilling.googleapis.com --project=${AUTOMATION_PROJECT}

# Deploy
terraform init
terraform plan
terraform apply
```

## Resources Created

### Stage 1 (12 resources)
- 6 organization policies (compute/SQL security)
- Organization IAM bindings
- Audit logs bucket: `my-org-org-audit-logs`
- Organization logging sink

### Stage 2 (Resource Hierarchy)

- Root folder: `my-org-landing-zones`
- Management folder: `management`
- Standard landing zone folder: `standard-landing-zone`
  - 6 org policies
  - 3 environment folders: dev, staging, prod
- Self-managed landing zone folder: `self-managed-landing-zone`
  - 1 org policy
- All IAM bindings for folders

## Next Steps

1. **Create your first project** in one of the landing zones
2. **Attach it to Shared VPC** (see README.md)
3. **Set up CI/CD** for this Terraform code
4. **Create budget alerts** for cost management
5. **Enable Security Command Center** for security monitoring

## Useful Commands

```bash
# List all folders
gcloud resource-manager folders list --organization=${ORG_ID}

# List all projects
gcloud projects list --filter="parent.id=${ORG_ID} parent.type=organization"

# View org policies
gcloud org-policies list --organization=${ORG_ID}

# Check logging sinks
gcloud logging sinks list --organization=${ORG_ID}
gcloud logging sinks list --folder=FOLDER_ID
```

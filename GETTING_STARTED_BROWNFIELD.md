# Getting Started - Brownfield GCP Organization

## What is Brownfield?

A brownfield deployment means your GCP organization **already has existing resources** like:
- Existing projects
- Existing folders
- Existing organization policies
- Existing IAM bindings
- Active workloads running

This guide helps you adopt this Terraform foundation without disrupting existing resources.

## Before You Start

Assess what you have:

```bash
# Set your organization ID
export ORG_ID="123456789012"
export ORG_NAME="organizations/${ORG_ID}"

# Login
gcloud auth login
gcloud auth application-default login

# Check existing folders
gcloud resource-manager folders list --organization=${ORG_ID} > existing-folders.txt

# Check existing projects
gcloud projects list --format="table(projectId,name,parent)" > existing-projects.txt

# Check existing org policies
gcloud org-policies list --organization=${ORG_ID} > existing-policies.txt

# Check org-level IAM
gcloud organizations get-iam-policy ${ORG_ID} > existing-org-iam.yaml

# Review these files to understand your current state
cat existing-folders.txt
cat existing-projects.txt
cat existing-policies.txt
```

## Deployment Strategies

### Strategy 1: Isolated Deployment (Recommended)

Deploy the foundation in a **dedicated folder** that doesn't interfere with existing resources.

**Best for**: Organizations that want to test the foundation or run it alongside existing structure.

#### Step 1: Assess Conflicts

```bash
# Check if any of these already exist:
# - Folders named "landing-zones", "management", "standard-landing-zone", "self-managed-landing-zone"
# - Projects with your prefix (e.g., "my-org-*")
# - Organization policies that might conflict

gcloud resource-manager folders list --organization=${ORG_ID} --filter="displayName:landing-zone"
```

#### Step 2: Deploy Bootstrap (Stage 0)

Follow the greenfield guide for Stage 0, using a **unique prefix** that won't conflict:

```bash
cd 0-bootstrap
export PREFIX="tf-managed"  # Use a unique prefix
export BILLING_ACCOUNT="YOUR-BILLING-ACCOUNT"
export ADMIN_EMAIL="your-admin@example.com"

cat > terraform.tfvars <<EOF
organization_id     = "${ORG_NAME}"
billing_account_id  = "${BILLING_ACCOUNT}"
prefix              = "${PREFIX}"
location            = "EU"

organization_admins = ["user:${ADMIN_EMAIL}"]
security_admins     = ["user:${ADMIN_EMAIL}"]
EOF

terraform init
terraform plan
terraform apply

export STATE_BUCKET=$(terraform output -raw terraform_state_bucket)
```

#### Step 3: Deploy Organization Policies (Stage 1) - CAREFULLY

**WARNING**: Organization policies affect the ENTIRE organization, including existing resources!

You have two options:

**Option A: Skip Stage 1** (Don't modify org-level policies)
- Skip this stage entirely if you don't want to change existing org policies
- Jump directly to Stage 2

**Option B: Import and Manage Existing Policies**
```bash
cd ../1-organization

# First, check which policies already exist
gcloud org-policies list --organization=${ORG_ID}

# For each existing policy, you'll need to import it
# Example for storage.uniformBucketLevelAccess:
terraform import 'module.organization.google_org_policy_policy.default["storage.uniformBucketLevelAccess"]' ${ORG_NAME}/policies/storage.uniformBucketLevelAccess

# Before applying, run terraform plan and review CAREFULLY
# Make sure it's not going to break existing workloads
terraform plan

# Only apply if you're confident
terraform apply
```

**Recommended**: Skip Stage 1 for brownfield deployments unless you specifically want to manage org policies with Terraform.

#### Step 4: Deploy Resource Hierarchy (Stage 2)

This creates a new folder structure that won't interfere with existing folders:

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

# Create provider.tf
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

logging_admins = ["user:${ADMIN_EMAIL}"]
self_managed_lz_admins = ["user:${ADMIN_EMAIL}"]
EOF

# REQUIRED: Edit main.tf
# 1. Comment out lines 79-82 (tag_bindings in standard_lz_folder)
# 2. Comment out lines 115-118 (tag_bindings in self_managed_lz_folder)
# 3. Verify line 69 has: destination = module.logging_bucket.name
# 4. Verify line 104 has: destination = module.logging_bucket.name

# Set environment
export GOOGLE_CLOUD_QUOTA_PROJECT="${PREFIX}-automation"
gcloud config set project ${PREFIX}-automation

# Grant permissions
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${ADMIN_EMAIL}" \
  --role="roles/resourcemanager.folderAdmin"

# Enable API
gcloud services enable cloudbilling.googleapis.com --project=${PREFIX}-automation

# Deploy
terraform init
terraform plan
terraform apply
```

**Result**: You now have a new folder structure like:
```
Organization
├── (your existing folders and projects) ← UNTOUCHED
└── tf-managed-landing-zones/ ← NEW
    ├── management/
    ├── standard-landing-zone/
    └── self-managed-landing-zone/
```

---

### Strategy 2: Import and Adopt Existing Resources

If you want to manage your **existing** folders/projects with this Terraform code, you need to import them.

**Best for**: Organizations ready to fully commit to Infrastructure-as-Code and willing to invest time in importing existing resources.

#### Step 1: Identify Resources to Import

```bash
# List existing folders with IDs
gcloud resource-manager folders list --organization=${ORG_ID} --format="table(name,displayName)"

# Example output:
# NAME                 DISPLAY_NAME
# folders/123456789    production
# folders/987654321    development
```

#### Step 2: Modify Terraform Code to Match Existing Structure

Edit `2-resource-hierarchy/main.tf` to match your existing folder names:

```hcl
module "root_folder" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.1.0"
  
  parent = var.organization_id
  name   = "production"  # Change to your existing folder name
  # ... rest of config
}
```

#### Step 3: Import Existing Resources

```bash
cd 2-resource-hierarchy

# Initialize Terraform
terraform init

# Import existing root folder
terraform import 'module.root_folder.google_folder.folder[0]' folders/123456789

# Import existing management folder
terraform import 'module.management_folder.google_folder.folder[0]' folders/987654321

# Import existing projects
terraform import 'module.logging_project.google_project.project[0]' projects/my-existing-logging-project

# Import existing IAM bindings
terraform import 'module.root_folder.google_folder_iam_binding.authoritative["roles/viewer"]' folders/123456789/roles/viewer

# Import existing org policies
terraform import 'module.standard_lz_folder.google_org_policy_policy.default["gcp.resourceLocations"]' folders/123456789/policies/gcp.resourceLocations

# After importing everything, run plan to verify
terraform plan

# Should show: 0 to add, 0 to change, 0 to destroy
# If it shows changes, you need to adjust the Terraform config to match existing resources
```

**This is complex and time-consuming!** You need to:
1. Import every folder, project, IAM binding, and policy
2. Match Terraform config exactly to existing resources
3. Test thoroughly before applying any changes

---

### Strategy 3: Hybrid Approach

Use Terraform for **new** resources only, leave existing resources as-is.

**Best for**: Organizations that want to start fresh for new workloads but keep existing infrastructure unchanged.

#### Approach:

1. **Deploy foundation in a new folder** (Strategy 1)
2. **Create new projects** in the Terraform-managed landing zones
3. **Gradually migrate** old projects to new structure when ready
4. **Keep existing** projects in their current folders

#### Migration Plan:

```
Phase 1: Deploy new foundation (Strategy 1)
  └─> New folder: "tf-managed-landing-zones"

Phase 2: Create new projects in Terraform-managed folders
  └─> All new workloads go here

Phase 3: Migrate existing projects (optional, over time)
  └─> Move projects from old folders to new folders
  └─> Use: gcloud projects move PROJECT_ID --folder=NEW_FOLDER_ID

Phase 4: Decommission old folders (when empty)
  └─> Delete old folders once all projects migrated
```

---

## Common Brownfield Challenges

### Challenge 1: Conflicting Organization Policies

**Problem**: Terraform wants to create a policy that already exists.

**Solution**:
```bash
# Option A: Import the existing policy
terraform import 'module.organization.google_org_policy_policy.default["POLICY_NAME"]' ${ORG_NAME}/policies/POLICY_NAME

# Option B: Remove the policy from Terraform code
# Comment out the policy in main.tf
```

### Challenge 2: Folder/Project Names Already Taken

**Problem**: Terraform tries to create a folder/project that already exists.

**Solution**:
```bash
# Option A: Import the existing resource
terraform import 'module.root_folder.google_folder.folder[0]' folders/FOLDER_ID

# Option B: Use a different prefix
# Change prefix in terraform.tfvars to something unique
```

### Challenge 3: IAM Binding Conflicts

**Problem**: Terraform uses `google_folder_iam_binding` (authoritative) which will remove existing IAM bindings.

**Solution**:
```bash
# Option A: Import all existing IAM bindings first
terraform import 'module.root_folder.google_folder_iam_binding.authoritative["roles/viewer"]' folders/FOLDER_ID/roles/viewer

# Option B: Modify Terraform to use non-authoritative bindings
# Change from google_folder_iam_binding to google_folder_iam_member in the module
```

### Challenge 4: Active Workloads Affected by New Policies

**Problem**: New org policies break existing workloads.

**Solution**:
```bash
# Test policies in a test folder first
# Use policy dry-run mode:
gcloud org-policies set-policy policy.yaml --dry-run

# Or skip Stage 1 entirely in brownfield deployments
```

---

## Recommended Brownfield Workflow

```bash
# 1. Assess current state
export ORG_ID="YOUR_ORG_ID"
export PREFIX="tf-managed"
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT"
export ADMIN_EMAIL="your-admin@example.com"

gcloud resource-manager folders list --organization=${ORG_ID}
gcloud projects list
gcloud org-policies list --organization=${ORG_ID}

# 2. Deploy bootstrap (Stage 0) with unique prefix
cd 0-bootstrap
# Follow greenfield guide with unique prefix

# 3. SKIP Stage 1 (organization policies)
# Don't modify existing org-level policies

# 4. Deploy resource hierarchy (Stage 2) in isolated folder
cd 2-resource-hierarchy
# Follow Strategy 1 above

# 5. Verify new folders created without conflicts
gcloud resource-manager folders list --organization=${ORG_ID}

# 6. Test with a new project in the new landing zone
gcloud projects create test-project-001 \
  --folder=STANDARD_LZ_FOLDER_ID \
  --name="Test Project"

# 7. If successful, start using new landing zones for new workloads
```

---

## Migration Checklist

- [ ] Document existing folder/project structure
- [ ] Document existing org policies
- [ ] Document existing IAM bindings
- [ ] Choose deployment strategy (isolated, import, or hybrid)
- [ ] Select unique prefix for Terraform resources
- [ ] Deploy bootstrap stage with unique prefix
- [ ] SKIP or carefully plan Stage 1 (org policies)
- [ ] Deploy Stage 2 in isolated folder
- [ ] Test with non-production workload
- [ ] Create runbook for migrating existing projects
- [ ] Plan gradual migration timeline
- [ ] Communicate changes to teams

---

## Getting Help

If you encounter issues during brownfield deployment:

1. **Check existing resources**: Use `gcloud` commands to see what already exists
2. **Use terraform plan carefully**: Review every change before applying
3. **Import first, then modify**: Always import existing resources before trying to manage them
4. **Test in non-production first**: Use a test org or folder to validate approach
5. **Keep backups**: Export existing policies and IAM bindings before making changes

---

## Useful Commands for Brownfield

```bash
# Export current org policies
for policy in $(gcloud org-policies list --organization=${ORG_ID} --format="value(name)"); do
  gcloud org-policies describe $policy --organization=${ORG_ID} > "backup-${policy}.yaml"
done

# Export folder structure
gcloud resource-manager folders list --organization=${ORG_ID} --format=json > backup-folders.json

# Export projects
gcloud projects list --format=json > backup-projects.json

# Move a project to new folder (when ready to migrate)
gcloud projects move PROJECT_ID --folder=NEW_FOLDER_ID

# Restore an org policy (if something breaks)
gcloud org-policies set-policy backup-POLICY_NAME.yaml
```

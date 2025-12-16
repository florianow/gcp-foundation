# GCP Permission Sets for meshStack

This module creates GCP organization-level custom IAM roles that serve as permission set templates for meshStack.

## Permission Sets

- **projectViewer** (`gcp-project-viewer`) - Read-only access
- **projectDeveloper** (`gcp-project-developer`) - Developer access without IAM/billing/org permissions
- **projectOperator** (`gcp-project-operator`) - SRE/ops access for production workloads

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Set your `organization_id` (numeric format: `123456789`)
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## meshStack Integration

After deployment, use the role IDs from outputs in meshStack configuration:
- Format: `organizations/{org_id}/roles/{role_id}`
- Example: `organizations/123456789/roles/projectDeveloper`

meshStack will reference these custom roles by ID when assigning permissions to projects.

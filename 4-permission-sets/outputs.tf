output "permission_set_ids" {
  description = "Map of permission set names to their GCP custom role IDs (for meshStack reference)"
  value = {
    "gcp-project-viewer"    = google_organization_iam_custom_role.project_viewer.id
    "gcp-project-developer" = google_organization_iam_custom_role.project_developer.id
    "gcp-project-operator"  = google_organization_iam_custom_role.project_operator.id
  }
}

output "permission_set_names" {
  description = "Map of permission set names to their role names (short form for meshStack)"
  value = {
    "gcp-project-viewer"    = google_organization_iam_custom_role.project_viewer.role_id
    "gcp-project-developer" = google_organization_iam_custom_role.project_developer.role_id
    "gcp-project-operator"  = google_organization_iam_custom_role.project_operator.role_id
  }
}

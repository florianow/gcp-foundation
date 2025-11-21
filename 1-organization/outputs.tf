output "organization_id" {
  description = "Organization ID"
  value       = var.organization_id
}

output "sink_writer_identities" {
  description = "Sink writer identities for audit logs"
  value       = module.organization.sink_writer_identities
}

output "networking_project_id" {
  description = "Networking hub project ID"
  value       = module.networking_project.project_id
}

output "shared_vpc_id" {
  description = "Shared VPC ID"
  value       = module.shared_vpc.id
}

output "shared_vpc_name" {
  description = "Shared VPC name"
  value       = module.shared_vpc.name
}

output "shared_vpc_self_link" {
  description = "Shared VPC self link"
  value       = module.shared_vpc.self_link
}

output "subnets" {
  description = "Subnet details"
  value       = module.shared_vpc.subnets
}

output "nat_gateway_id" {
  description = "Cloud NAT gateway ID"
  value       = module.nat_gateway_eu.id
}

output "private_dns_zone_name" {
  description = "Private DNS zone name"
  value       = module.dns_private_zone.name
}

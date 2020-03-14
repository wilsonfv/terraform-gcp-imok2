output "network" {
  value       = module.standalone-vpc-network.network
  description = "The VPC resource being created"
}

output "network_name" {
  value       = module.standalone-vpc-network.network_name
  description = "The name of the VPC being created"
}

output "network_self_link" {
  value       = module.standalone-vpc-network.network_self_link
  description = "The URI of the VPC being created"
}

output "validation_result" {
  value       = data.external.validation.result
  description = "The validation result"
}
module "create_service_project_standalone_vpc_network" {
  source                                  = "../../../module/data-networks/vpc-network"
  project_id                              = var.project_id
  network_continent                       = var.network_continent
  network_name                            = var.network_name
  description                             = var.description
  subnets                                 = var.subnets
  secondary_ranges                        = var.secondary_ranges
  custom_firewall_rules                   = var.custom_firewall_rules
  enable_fw_cloud_dns_ingress             = var.enable_fw_cloud_dns_ingress
  enable_fw_lb_health_check_egress        = var.enable_fw_lb_health_check_egress
  enable_fw_lb_health_check_ingress       = var.enable_fw_lb_health_check_ingress
  enable_fw_restricted_google_apis_egress = var.enable_fw_restricted_google_apis_egress
}

output "validation_result" {
  value       = module.create_service_project_standalone_vpc_network.validation_result
  description = "The validation result"
}
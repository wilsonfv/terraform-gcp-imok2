locals {

}

module "multiple-standalone-vpc-networks" {
  source = "../standalone-vpc-network"
  for_each = var.networks
  service_project_id = var.service_project_id
  network_continent = var.network_continent
  network_name = each.value.network_name
  description = each.value.description
  subnets = each.value.subnets
  secondary_ranges = each.value.secondary_ranges
  custom_firewall_rules = each.value.firewall_rules
  enable_fw_restricted_google_apis_egress = lookup(each.value.extra_attributes, "enable_fw_restricted_google_apis_egress", false)
  enable_fw_lb_health_check_ingress = lookup(each.value.extra_attributes, "enable_fw_lb_health_check_ingress", false)
  enable_fw_lb_health_check_egress = lookup(each.value.extra_attributes, "enable_fw_lb_health_check_egress", false)
  enable_fw_cloud_dns_ingress = lookup(each.value.extra_attributes, "enable_fw_cloud_dns_ingress", false)
}
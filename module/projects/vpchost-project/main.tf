module "vpchost-project" {
  source = "../base-project"

  project_id      = var.project_id
  org_id          = var.org_id
  folder_id       = var.folder_id
  domain          = var.domain
  billing_account = var.billing_account
  activate_apis   = var.activate_apis
}

module "vpc_network" {
  source                                  = "../../../module/data-networks/vpc-network"
  project_id                              = module.vpchost-project.project_id
  network_continent                       = var.network_continent
  network_name                            = var.network_name
  description                             = var.description
  subnets                                 = var.subnets
  secondary_ranges                        = var.secondary_ranges
  custom_firewall_rules                   = var.custom_firewall_rules
  shared_vpc_host                         = true
  enable_fw_cloud_dns_ingress             = true
  enable_fw_lb_health_check_egress        = true
  enable_fw_lb_health_check_ingress       = true
  enable_fw_restricted_google_apis_egress = true
}

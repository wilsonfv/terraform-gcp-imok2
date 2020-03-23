variable "service_project_id" {
  description = "The ID of the project"
}

locals {
  network_name = "${var.service_project_id}-standalone-vpc"

  network_continent = "EU"

  subnet1_region   = "europe-west2"
  subnet1_gke_name = "${local.network_name}-subnet-gke-${local.subnet1_region}"

  subnet2_region   = "europe-west1"
  subnet2_gke_name = "${local.network_name}-subnet-gke-${local.subnet2_region}"
}

module "create_service_project_standalone_vpc_network" {
  source                                  = "../../../data-networks/standalone-vpc-network"
  service_project_id                      = var.service_project_id
  network_continent                       = local.network_continent
  network_name                            = local.network_name
  enable_fw_cloud_dns_ingress             = true
  enable_fw_lb_health_check_egress        = true
  enable_fw_lb_health_check_ingress       = true
  enable_fw_restricted_google_apis_egress = true

  subnets = [
    {
      subnet_name           = local.subnet1_gke_name
      subnet_ip             = "192.168.192.0/23"
      subnet_region         = local.subnet1_region
      subnet_private_access = true
    },
    {
      subnet_name           = local.subnet2_gke_name
      subnet_ip             = "192.168.194.0/23"
      subnet_region         = local.subnet2_region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    "${local.subnet1_gke_name}" = [
      {
        range_name    = "pods"
        ip_cidr_range = "192.168.128.0/19"
      },
      {
        range_name    = "services"
        ip_cidr_range = "192.168.208.0/21"
      },
    ]
    "${local.subnet2_gke_name}" = [
      {
        range_name    = "pods"
        ip_cidr_range = "192.168.160.0/19"
      },
      {
        range_name    = "services"
        ip_cidr_range = "192.168.216.0/21"
      },
    ]
  }

  custom_firewall_rules = {
    allow-gke-master-egress = {
      description          = "firewall rule to allow traffic to gke master ip range"
      direction            = "EGRESS"
      action               = "allow"
      ranges               = ["172.16.0.0/28"]
      sources              = []
      targets              = []
      use_service_accounts = false
      rules = [
        {
          protocol = "tcp"
          ports    = ["443", "10250"]
        }
      ]
      extra_attributes = {
        enable_logging = true
      }
    }
  }
}

output "validation_result" {
  value       = module.create_service_project_standalone_vpc_network.validation_result
  description = "The validation result"
}
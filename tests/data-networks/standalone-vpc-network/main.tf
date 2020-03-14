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
  source                 = "../../../data-networks/standalone-vpc-network"
  service_project_id     = var.service_project_id
  network_continent      = local.network_continent
  network_name           = local.network_name

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
}

output "validation_result" {
  value       = module.create_service_project_standalone_vpc_network.validation_result
  description = "The validation result"
}
/******************************************
	validation
 *****************************************/
data "external" "validation" {
  program = ["python", "${path.module}/scripts/validation.py"]

  query = {
    network_continent = jsonencode(var.network_continent)
    subnets           = jsonencode(var.subnets)
    secondary_ranges  = jsonencode(var.secondary_ranges)
  }
}

/******************************************
	VPC configuration
 *****************************************/
module "standalone-vpc-network" {
  source       = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/vpc?ref=master"
  project_id   = var.service_project_id
  network_name = var.network_name
  description  = var.description
}

/******************************************
	Subnet configuration
 *****************************************/
module standalone-subnet {
  source           = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/subnets?ref=master"
  project_id       = var.service_project_id
  network_name     = module.standalone-vpc-network.network_name
  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
}

/******************************************
    firewall rule
 *****************************************/
resource "google_compute_firewall" "default-deny-egress" {
  name               = "fw-${module.standalone-vpc-network.network_name}-default-deny-egress"
  network            = module.standalone-vpc-network.network_self_link
  project            = var.service_project_id
  priority           = "65535"
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
}
//
//resource "google_compute_firewall" "fw-internal-ingress" {
//  for_each      = var.enable_fw_internal_ingress ? local.subnets : {}
//  name          = "fw-${each.value.subnet_name}-internal-ingress"
//  network       = google_compute_network.network.self_link
//  project       = var.service_project_id
//  direction     = "INGRESS"
//  source_ranges = [each.value.subnet_ip]
//  allow {
//    protocol = "tcp"
//  }
//  allow {
//    protocol = "udp"
//  }
//}
//
//resource "google_compute_firewall" "fw-internal-egress" {
//  for_each           = var.enable_fw_internal_egress ? local.subnets : {}
//  name               = "fw-${each.value.subnet_name}-internal-egress"
//  network            = google_compute_network.network.self_link
//  project            = var.service_project_id
//  direction          = "EGRESS"
//  destination_ranges = [each.value.subnet_ip]
//  allow {
//    protocol = "tcp"
//  }
//  allow {
//    protocol = "udp"
//  }
//}
//
resource "google_compute_firewall" "fw-restricted-google-apis-egress" {
  count              = var.enable_fw_restricted_google_apis_egress ? 1 : 0
  name               = "fw-${module.standalone-vpc-network.network_name}-restricted-google-apis-egress"
  network            = module.standalone-vpc-network.network_self_link
  project            = var.service_project_id
  direction          = "EGRESS"
  destination_ranges = ["199.36.153.4/30"]
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
//
//resource "google_compute_firewall" "fw-lb-health-check-ingress" {
//  count         = var.enable_fw_lb_health_check_ingress ? 1 : 0
//  name          = "fw-${var.network_name}-lb-health-check-ingress"
//  network       = google_compute_network.network.self_link
//  project       = var.service_project_id
//  direction     = "INGRESS"
//  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
//  allow {
//    protocol = "tcp"
//    ports    = ["80", "443"]
//  }
//  target_tags = ["t-${var.network_name}-lb-health-check-ingress"]
//}
//
//resource "google_compute_firewall" "fw-lb-health-check-egress" {
//  count              = var.enable_fw_lb_health_check_egress ? 1 : 0
//  name               = "fw-${var.network_name}-lb-health-check-egress"
//  network            = google_compute_network.network.self_link
//  project            = var.service_project_id
//  direction          = "EGRESS"
//  destination_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
//  allow {
//    protocol = "tcp"
//    ports    = ["80", "443"]
//  }
//  target_tags = ["t-${var.network_name}-lb-health-check-egress"]
//}
//
//resource "google_compute_firewall" "fw-cloud-dns-ingress" {
//  count         = var.enable_fw_cloud_dns_ingress ? 1 : 0
//  name          = "fw-${var.network_name}-cloud-dns-ingress"
//  network       = google_compute_network.network.self_link
//  project       = var.service_project_id
//  direction     = "INGRESS"
//  source_ranges = ["35.199.192.0/19"]
//  allow {
//    protocol = "tcp"
//    ports    = ["53"]
//  }
//  allow {
//    protocol = "udp"
//    ports    = ["53"]
//  }
//  target_tags = ["t-${var.network_name}-cloud-dns-ingress"]
//}

/******************************************
	route
 *****************************************/
module "default_routes" {
  source                                 = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/routes?ref=master"
  project_id                             = var.service_project_id
  network_name                           = module.standalone-vpc-network.network_name
  delete_default_internet_gateway_routes = true
  routes = [
    {
      name              = "restriced-google-apis"
      description       = "route to restriced google api endpoints"
      destination_range = "199.36.153.4/30"
      next_hop_internet = "true"
    }
  ]
}
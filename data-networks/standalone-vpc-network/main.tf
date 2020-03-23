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
module "custom-firewall-rule" {
  source              = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/fabric-net-firewall?ref=master"
  network             = module.standalone-vpc-network.network_self_link
  project_id          = var.service_project_id
  ssh_source_ranges   = []
  http_source_ranges  = []
  https_source_ranges = []
  custom_rules = merge(
    {
      default-deny-egress = {
        description          = "default deny all egress"
        direction            = "EGRESS"
        action               = "deny"
        ranges               = ["0.0.0.0/0"]
        sources              = []
        targets              = []
        use_service_accounts = false
        rules = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          }
        ]
        extra_attributes = {
          enable_logging = true
          priority       = "65535"
        }
      }
    }
    ,
    var.enable_fw_restricted_google_apis_egress == true ?
    {
      fw-restricted-google-apis-egress = {
        description          = "allow traffic to restricted google apis"
        direction            = "EGRESS"
        action               = "allow"
        ranges               = ["199.36.153.4/30"]
        sources              = []
        targets              = []
        use_service_accounts = false
        rules = [
          {
            protocol = "tcp"
            ports    = ["443"]
          }
        ]
        extra_attributes = {
          enable_logging = true
        }
      }
    } : {}
    ,
    var.enable_fw_lb_health_check_ingress == true ?
    {
      fw-lb-health-check-ingress = {
        description          = "allow ingress traffic for health check"
        direction            = "INGRESS"
        action               = "allow"
        ranges               = ["130.211.0.0/22", "35.191.0.0/16"]
        sources              = []
        targets              = []
        use_service_accounts = false
        rules = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        extra_attributes = {
          enable_logging = true
        }
      }
    } : {}
    ,
    var.enable_fw_lb_health_check_egress == true ?
    {
      fw-lb-health-check-egress = {
        description          = "allow egress traffic for health check"
        direction            = "EGRESS"
        action               = "allow"
        ranges               = ["130.211.0.0/22", "35.191.0.0/16"]
        sources              = []
        targets              = []
        use_service_accounts = false
        rules = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        extra_attributes = {
          enable_logging = true
        }
      }
    } : {}
    ,
    var.enable_fw_cloud_dns_ingress == true ?
    {
      fw-cloud-dns-ingress = {
        description          = "allow ingress traffic for cloud dns"
        direction            = "INGRESS"
        action               = "allow"
        ranges               = ["35.199.192.0/19"]
        sources              = []
        targets              = ["t-${module.standalone-vpc-network.network_name}-cloud-dns-ingress"]
        use_service_accounts = false
        rules = [
          {
            protocol = "tcp"
            ports    = ["53"]
          },
          {
            protocol = "udp"
            ports    = ["53"]
          }
        ]
        extra_attributes = {
          enable_logging = true
        }
      }
    } : {}
    ,
    var.custom_firewall_rules
  )
}

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

/******************************************
	Cloud DNS Private Zone
 *****************************************/
resource "google_dns_managed_zone" "google-apis" {
  name        = "google-apis"
  project     = var.service_project_id
  dns_name    = "googleapis.com."
  description = "private zone for Google API's"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = module.standalone-vpc-network.network_self_link
    }
  }
}

resource "google_dns_record_set" "restricted-google-apis-A-record" {
  name    = "restricted.googleapis.com."
  project = var.service_project_id
  type    = "A"
  ttl     = 300

  managed_zone = google_dns_managed_zone.google-apis.name

  rrdatas = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
}

resource "google_dns_record_set" "google-api-CNAME" {
  name    = "*.googleapis.com."
  project = var.service_project_id
  type    = "CNAME"
  ttl     = 300

  managed_zone = google_dns_managed_zone.google-apis.name

  rrdatas = ["restricted.googleapis.com."]
}

resource "google_dns_managed_zone" "gcr-io" {
  name        = "gcr-io"
  project     = var.service_project_id
  dns_name    = "gcr.io."
  description = "private zone for GCR.io"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = module.standalone-vpc-network.network_self_link
    }
  }
}

resource "google_dns_record_set" "restricted-gcr-io-A-record" {
  name    = "gcr.io."
  project = var.service_project_id
  type    = "A"
  ttl     = 300

  managed_zone = google_dns_managed_zone.gcr-io.name

  rrdatas = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
}

resource "google_dns_record_set" "gcr-io-CNAME" {
  name    = "*.gcr.io."
  project = var.service_project_id
  type    = "CNAME"
  ttl     = 300

  managed_zone = google_dns_managed_zone.gcr-io.name

  rrdatas = ["gcr.io."]
}

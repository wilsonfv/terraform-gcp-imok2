variable "service_project_id" {
  description = "The ID of the project where this VPC will be created"
}

variable "network_continent" {
  type = string
  description = "the continent in which standalone vpc network will be created, it must be one of these values (EU, ASIA, US)"
}

variable "network_name" {
  description = "The name of the network being created"
}

variable "description" {
  type        = string
  description = "An optional description of this resource. The resource must be recreated to modify this field."
  default     = ""
}

/*
subnets example
https://github.com/terraform-google-modules/terraform-google-network/tree/master/modules/subnets

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-west1"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "This subnet has a description"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-west1"
            subnet_flow_logs          = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
        }
    ]
*/
variable "subnets" {
  type        = list(map(string))
  description = "The list of subnets being created"
}

/*
secondary_ranges example
https://github.com/terraform-google-modules/terraform-google-network/tree/master/modules/subnets

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]

        subnet-02 = []
    }
*/
variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default     = {}
}

//variable "enable_fw_internal_ingress" {
//  type        = bool
//  description = "whether to create ingress firewall rule for intra-vpc connection"
//  default     = false
//}
//
//variable "enable_fw_internal_egress" {
//  type        = bool
//  description = "whether to create egress firewall rule for intra-vpc connection"
//  default     = false
//}

variable "enable_fw_restricted_google_apis_egress" {
  type        = bool
  description = "whether to create egress firewall rule for restricted google apis"
  default     = false
}

variable "enable_fw_lb_health_check_ingress" {
  type        = bool
  description = "whether to create ingress firewall rule for load balancer health check"
  default     = false
}

variable "enable_fw_lb_health_check_egress" {
  type        = bool
  description = "whether to create egress firewall rule for load balancer health check"
  default     = false
}

variable "enable_fw_cloud_dns_ingress" {
  type        = bool
  description = "whether to create ingress firewall rule for cloud dns"
  default     = false
}

variable "custom_firewall_rules" {
  description = "List of custom rule definitions (refer to variables file for syntax)."
  default     = {}
  type = map(object({
    description          = string
    direction            = string
    action               = string # (allow|deny)
    ranges               = list(string)
    sources              = list(string)
    targets              = list(string)
    use_service_accounts = bool
    rules = list(object({
      protocol = string
      ports    = list(string)
    }))
    extra_attributes = map(string)
  }))
}
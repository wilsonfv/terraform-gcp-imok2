variable "project_id" {
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

variable "subnets" {
  type        = list(map(string))
  description = "The list of subnets being created"
}

variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default     = {}
}

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
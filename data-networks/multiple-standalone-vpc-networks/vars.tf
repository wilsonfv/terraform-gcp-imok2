variable "service_project_id" {
  description = "The ID of the project where a list of VPC will be created"
}

variable "network_continent" {
  type        = string
  description = "the continent in which standalone vpc network will be created, it must be one of these values (EU, ASIA, US)"
}

variable "networks" {
  description = "the vpc network"
  type = list(map(object({
    network_name = string
    description = string
    subnets      = list(map(string))
    secondary_ranges = map(list(object({
      range_name    = string,
      ip_cidr_range = string
    })))
    firewall_rules = map(object({
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
    routes           = list(map(string))
    extra_attributes = map(string)
  })))
  default = []
}
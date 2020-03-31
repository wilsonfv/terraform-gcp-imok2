module "base-project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 7.1"

  name                    = var.project_id
  project_id              = var.project_id
  org_id                  = var.org_id
  folder_id               = var.folder_id
  domain                  = var.domain
  billing_account         = var.billing_account
  shared_vpc              = var.shared_vpc
  shared_vpc_subnets      = var.shared_vpc_subnets
  default_service_account = "keep"
  skip_gcloud_download    = true
  activate_apis = concat(
    ["cloudbilling.googleapis.com",
    "dns.googleapis.com"],
  var.activate_apis)
}
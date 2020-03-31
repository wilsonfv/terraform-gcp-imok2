module "create-service-project" {
  source             = "../../../module/projects/base-project"
  org_id             = var.org_id
  folder_id          = var.folder_id
  project_id         = var.project_id
  billing_account    = var.billing_account
  shared_vpc         = var.shared_vpc
  shared_vpc_subnets = var.shared_vpc_subnets
}
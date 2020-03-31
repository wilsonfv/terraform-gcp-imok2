module "create-vpchost-project" {
  source            = "../../../module/projects/vpchost-project"
  org_id            = var.org_id
  folder_id         = var.folder_id
  project_id        = var.project_id
  billing_account   = var.billing_account
  network_continent = var.network_continent
  network_name      = var.network_name
  description       = var.description
  subnets           = var.subnets
  secondary_ranges  = var.secondary_ranges
}
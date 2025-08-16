data "cloudflare_zones" "zone" {
  name = var.zone_name
}

locals {
  zone_result = data.cloudflare_zones.zone.result
  zone_id     = data.cloudflare_zones.zone.result[0].id
  account_id  = data.cloudflare_zones.zone.result[0].account.id
}


module "dns" {
  source             = "./modules/dns"
  pages_project_name = var.pages_project_name
  zone_name          = var.zone_name
  zone_id            = local.zone_id
}

# module "pages" {
#   source = "./modules/pages"

#   account_id         = local.account_id
#   pages_project_name = var.pages_project_name
#   domain             = var.prod_domain
#   github_owner       = var.github_owner
#   repo_name          = var.repo_name
# }

module "security" {
  source = "./modules/security"

  zone_id = local.zone_id
}
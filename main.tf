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

module "security" {
  source = "./modules/security"

  zone_id = local.zone_id
  domain  = var.domain
}

module "speed" {
  source = "./modules/speed"

  zone_id = local.zone_id
}

module "cache" {
  source = "./modules/cache"

  zone_id = local.zone_id
}

module "queue" {
  source = "./modules/queues"

  account_id              = local.account_id
  zone_id                 = local.zone_id
  upstash_database_name   = var.upstash_database_name
  upstash_database_region = var.upstash_database_region
}

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
  pages_project_name = var.project_name
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

module "queues" {
  source = "./modules/queues"

  upstash_database_name   = var.upstash_database_name
  upstash_database_region = var.upstash_database_region
}

module "workers" {
  source = "./modules/workers"

  account_id             = local.account_id
  zone_id                = local.zone_id
  loki_endpoint          = var.loki_endpoint
  loki_password          = var.loki_password
  loki_user              = var.loki_user
  upstash_rest_token     = module.queues.upstash_rest_token
  upstash_rest_url       = module.queues.upstash_rest_url
  r2_bucket_name         = var.bucket_name
  neon_database_url      = module.database.neon_database_url
  revalidate_token       = var.revalidate_token
  next_revalidate_secret = var.next_revalidate_secret
  api_purge_token        = var.api_purge_token
  next_host              = var.next_host
  domain                 = var.domain

  depends_on = [
    module.r2
  ]
}

module "r2" {
  source = "./modules/r2"

  account_id  = local.account_id
  zone_id     = local.zone_id
  bucket_name = var.bucket_name
}

module "database" {
  source = "./modules/database"

  db_name      = var.neon_db_name
  project_name = var.project_name
  neon_api_key = var.neon_api_key
}

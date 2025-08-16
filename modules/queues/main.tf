############################
###### Upstash Redis ######
############################
resource "upstash_redis_database" "redis" {
  database_name  = var.upstash_database_name
  region         = "global"
  primary_region = var.upstash_database_region
  tls            = true
}

# Saídas úteis: rest_url/rest_token/endpoint/password variam por plano — muitos ambientes expõem rest_*.
# Se seu provider não retornar rest_* publicamente, copie do painel e passe via variables/secrets.
locals {
  upstash_rest_url   = upstash_redis_database.redis.endpoint
  upstash_rest_token = upstash_redis_database.redis.rest_token
}

############################
##### Worker Producer ######
############################

# Worker que recebe HTTP e faz XADD na stream
resource "cloudflare_workers_script" "producer" {
  account_id         = var.account_id
  script_name        = var.worker_name
  content            = file("${path.module}/scripts/producer.mjs")
  main_module        = "producer.mjs"
  compatibility_date = "2024-12-01"
  usage_model        = "standard"

  bindings = [
    {
      name = "UPSTASH_REDIS_REST_URL"
      text = local.upstash_rest_url
      type = "secret_text"
    },
    {
      name = "UPSTASH_REDIS_REST_TOKEN"
      text = local.upstash_rest_token
      type = "secret_text"
    },
    {
      name = "STREAM_KEY"
      text = var.stream_key
      type = "secret_text"
    }
  ]
}

# Rota pública opcional para o producer
resource "cloudflare_workers_route" "route" {
  count   = length(var.route_pattern) > 0 ? 1 : 0
  zone_id = var.zone_id
  script  = cloudflare_workers_script.producer.script_name
  pattern = var.route_pattern
}

############################
###### Cloudflare KV ######
############################
resource "cloudflare_workers_kv_namespace" "cursors" {
  account_id = var.account_id
  title      = var.kv_namespace_name
}

############################
##### Worker Consumer ######
############################
# Arquivo do worker
resource "cloudflare_workers_script" "consumer" {
  account_id         = var.account_id
  script_name        = var.worker_name
  content            = file("${path.module}/scripts/consumer.mjs")
  main_module        = "consumer.mjs"
  compatibility_date = "2024-12-01"
  usage_model        = "standard"

  bindings = [
    {
      name         = "CURSORS"
      namespace_id = cloudflare_workers_kv_namespace.cursors.id
      type         = "kv_namespace"
    },
    {
      name = "UPSTASH_REDIS_REST_URL"
      text = local.upstash_rest_url
      type = "secret_text"
    },
    {
      name = "UPSTASH_REDIS_REST_TOKEN"
      text = local.upstash_rest_token
      type = "secret_text"
    },
    {
      name = "STREAM_KEY"
      text = var.stream_key
      type = "secret_text"
    },
    {
      name = "KV_CURSOR_KEY"
      text = var.kv_cursor_key
      type = "secret_text"
    }
  ]
}

# Cron Trigger (agenda o worker)
resource "cloudflare_workers_cron_trigger" "schedule" {
  account_id  = var.account_id
  script_name = cloudflare_workers_script.consumer.script_name
  schedules = [
    { cron = var.cron_schedule }
  ] # ex.: "*/1 * * * *"
}

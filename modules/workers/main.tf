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
      text = var.upstash_rest_url
      type = "secret_text"
    },
    {
      name = "UPSTASH_REDIS_REST_TOKEN"
      text = var.upstash_rest_token
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

  lifecycle {
    prevent_destroy = true
  }
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
      text = var.upstash_rest_url
      type = "secret_text"
    },
    {
      name = "UPSTASH_REDIS_REST_TOKEN"
      text = var.upstash_rest_token
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
    },
    {
      name = "LOKI_USERNAME"
      text = var.loki_user
      type = "secret_text"
    },
    {
      name = "LOKI_ENDPOINT"
      text = var.loki_endpoint
      type = "secret_text"
    },
    {
      name = "LOKI_PASSWORD"
      text = var.loki_password
      type = "secret_text"
    },
    {
      name = "LOG_APP"
      text = var.log_app
      type = "secret_text"
    },
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

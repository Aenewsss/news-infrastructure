# SOMENTE NO PLANO PAGO

############################
########## Queue ##########
############################
resource "cloudflare_queue" "flush" {
  account_id = var.account_id
  queue_name = var.queue_name
}

############################
##### Worker Consumer #####
############################
resource "cloudflare_workers_script" "consumer" {
  account_id         = var.account_id
  script_name        = var.consumer_name
  content            = file("${path.module}/scripts/consumer.mjs")
  main_module        = "index.mjs"
  compatibility_date = "2024-12-01"
  usage_model        = "standard"
}

# Liga a fila ao consumer (push-based)
resource "cloudflare_queue_consumer" "flush_consumer" {
  account_id  = var.account_id
  queue_id    = cloudflare_queue.flush.id
  script_name = cloudflare_workers_script.consumer.script_name
  type        = "worker"

  # Batch defaults (ajuste se quiser); valores comuns: 10 msgs / 5s
  settings = {
    batch_size       = 10
    max_wait_time_ms = 5

    max_batch_size    = 10
    max_batch_timeout = 5
  }

}

############################
##### Worker Producer #####
############################

resource "cloudflare_workers_script" "producer" {
  account_id         = var.account_id
  script_name        = var.producer_name
  content            = file("${path.module}/scripts/producer.mjs")
  main_module        = "producer.mjs"
  compatibility_date = "2024-12-01"
  usage_model        = "standard"

  # Binding de producer -> queue (variável JS: env.FLUSH_QUEUE)
  # (Provider v5 expõe bindings; tipo "queue" aceita queue_name)
  bindings = [
    {
      type       = "queue"
      name       = "FLUSH_QUEUE"
      queue_name = cloudflare_queue.flush.queue_name
    }
  ]
}

############################
###### Producer Route ######
############################

# OBS: só é necessário se você quiser expor um endpoint HTTP na Cloudflare para injetar mensagens na fila, se for chamar
# direto no pages ou worker, não precisa

resource "cloudflare_workers_route" "producer_route" {
  count   = length(var.producer_route) > 0 ? 1 : 0
  zone_id = var.zone_id
  script  = cloudflare_workers_script.producer.script_name
  pattern = var.producer_route
}

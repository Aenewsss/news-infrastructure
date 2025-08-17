variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "consumer_worker_name" {
  type    = string
  default = "redis-stream-consumer"
}
variable "uploader_worker_name" {
  type    = string
  default = "portal-uploader"
}
variable "producer_worker_name" {
  type    = string
  default = "redis-stream-producer"
}
variable "cron_schedule" {
  type    = string
  default = "*/1 * * * *"
} # a cada 1 min

# Nome da stream e chave de cursor em KV
variable "stream_key" {
  type    = string
  default = "views"
}
variable "kv_namespace_name" {
  type    = string
  default = "STREAM_CURSORS"
}
variable "kv_cursor_key" {
  type    = string
  default = "views:last_id"
}

variable "route_pattern" {
  type    = string
  default = ""
  # ex: "www.seudominio.com/api/track*"
}

variable "loki_endpoint" {
  type = string
}

variable "loki_user" {
  type = string
}

variable "loki_password" {
  type = string
}

variable "log_app" {
  type    = string
  default = "news-portal"
}

variable "upstash_rest_url" {
  type = string
}
variable "upstash_rest_token" {
  type = string
}

# Regras simples de upload
variable "max_upload_bytes" {
  type    = number
  default = 10000000
} # ~10MB

variable "allowed_mime_prefixes" {
  type    = list(string)
  default = ["image/", "video/"] # ajuste se quiser permitir mais
}

variable "r2_bucket_name" {
  type = string
}

variable "neon_database_url" {
  type = string
}

variable "api_purge_token" {
  type = string
}

variable "revalidate_token" {
  type = string
}

variable "next_revalidate_secret" {
  type = string
}

variable "next_host" {
  type = string
}

variable "domain" {
  type = string
}

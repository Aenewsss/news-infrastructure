variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "worker_name" {
  type    = string
  default = "redis-stream-consumer"
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

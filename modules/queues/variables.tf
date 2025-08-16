variable "upstash_database_name" {
  type = string
}

variable "upstash_database_region" {
  type = string
}

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

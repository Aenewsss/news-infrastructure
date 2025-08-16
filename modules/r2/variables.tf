variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
} # para a rota HTTP

variable "bucket_name" {
  type = string
} # ex: "news-media"

variable "worker_name" {
  type    = string
  default = "r2-uploader"
}

variable "route_pattern" {
  type    = string
  default = ""
} # ex: "media.seudominio.com/*" ou "www.seudominio.com/api/media/*"

# CORS básicos (ajuste conforme seu domínio)
variable "cors_allowed_origins" {
  type    = list(string)
  default = ["*"]
}

variable "cors_allowed_methods" {
  type    = list(string)
  default = ["GET", "PUT", "POST", "DELETE"]
}

variable "cors_allowed_headers" {
  type    = list(string)
  default = ["*"]
}

variable "cors_max_age" {
  type    = number
  default = 3600
}
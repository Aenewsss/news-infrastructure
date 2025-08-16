variable "cloudflare_api_token" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "pages_project_name" {
  type    = string
  default = "portal-frontend"
}
variable "domain" {
  type    = string
  default = "lab-portal"
}

variable "upstash_api_key" {
  type = string
}

variable "upstash_email" {
  type = string
}

variable "upstash_database_name" {
  type = string
}

variable "upstash_database_region" {
  type    = string
  default = "us-east-1"
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

variable "bucket_name" {
  type = string
}
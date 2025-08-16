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

variable "github_owner" {
  type = string
}

variable "repo_name" {
  type = string
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

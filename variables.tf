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
variable "prod_domain" {
  type    = string
  default = "lab-portal"
}

variable "github_owner" {
  type = string
}

variable "repo_name" {
  type = string
}

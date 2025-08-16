terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.8.4"
    }
  }

}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

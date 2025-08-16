terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.8.4"
    }

    upstash = {
      source  = "upstash/upstash"
      version = "1.5.3"
    }

    neon = {
      source  = "kislerdm/neon"
      version = "0.9.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "upstash" {
  api_key = var.upstash_api_key
  email   = var.upstash_email
}

provider "neon" {
  api_key = var.neon_api_key
}

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
  }
}

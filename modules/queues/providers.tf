terraform {
  required_version = ">= 1.6"

  required_providers {
    upstash = {
      source  = "upstash/upstash"
      version = "1.5.3"
    }
  }
}

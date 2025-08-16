resource "cloudflare_ruleset" "security_headers" {
  zone_id = var.zone_id
  name    = "Security headers"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules = [{
    ref         = "modify_request_headers"
    enabled     = true
    description = "Add security headers"
    expression  = "true"
    action      = "rewrite"
    action_parameters = {
      headers = {
        "Strict-Transport-Security" = {
          operation = "set"
          value     = "max-age=31536000; includeSubDomains; preload"
        }
        "X-Content-Type-Options" = {
          operation = "set"
          value     = "nosniff"
        }
        "Referrer-Policy" = {
          operation = "set"
          value     = "strict-origin-when-cross-origin"
        }
        "X-Frame-Options" = {
          operation = "set"
          value     = "DENY"
        }
      }
    }
  }]
}

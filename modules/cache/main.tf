resource "cloudflare_ruleset" "cache_rules" {
  zone_id = var.zone_id
  name    = "Cache rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [
    # 3.1 Cache estático por extensão
    {
      enabled     = true
      description = "Cache static assets (1y)"
      # Ideal usar o operador matches aqui, mas o plano gratuito não permite
      expression = "((ends_with(http.request.uri.path, \".css\")) or (ends_with(http.request.uri.path, \".js\")) or (ends_with(http.request.uri.path, \".mjs\")) or (ends_with(http.request.uri.path, \".png\")) or (ends_with(http.request.uri.path, \".jpg\")) or (ends_with(http.request.uri.path, \".jpeg\")) or (ends_with(http.request.uri.path, \".webp\")) or (ends_with(http.request.uri.path, \".gif\")) or (ends_with(http.request.uri.path, \".svg\")) or (ends_with(http.request.uri.path, \".ico\")) or (ends_with(http.request.uri.path, \".woff\")) or (ends_with(http.request.uri.path, \".woff2\")) or (ends_with(http.request.uri.path, \".ttf\")) or (ends_with(http.request.uri.path, \".map\")) or (ends_with(http.request.uri.path, \".avi\")))"
      action     = "set_cache_settings"
      action_parameters = {
        edge_ttl = {
          default = 31536000
          mode    = "override_origin"
        }
        cache = true
        browser_ttl = {
          default = 31536000
          mode    = "override_origin"
        }
        respect_origin = false
      }
    },

    # 3.2 Bypass para admin/API
    {
      enabled     = true
      description = "Bypass admin and API"
      expression  = "(starts_with(http.request.uri.path, \"/admin\") or starts_with(http.request.uri.path, \"/api\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = false
      }
    },

    # 3.3 respeitar os headers do origin (Next/Pages controlam)
    {
      enabled     = true
      description = "Others: respect origin cache headers"
      expression  = "true"
      action      = "set_cache_settings"

      action_parameters = {
        cache = true

        edge_ttl = {
          mode = "respect_origin"
        }

        browser_ttl = {
          mode = "respect_origin"
        }
      }
    }
  ]
}

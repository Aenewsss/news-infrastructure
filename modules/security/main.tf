locals {
  zone_settings = {
    brotli                   = "on"   # compressão Brotli (melhor que GZIP)
    http3                    = "on"   # HTTP/3 (QUIC)
    always_use_https         = "on"   # redireciona http -> https
    automatic_https_rewrites = "on"   # reescreve URLs http -> https
    opportunistic_encryption = "on"   # OCSP stapling / conexões oportunistas
    websockets               = "on"   # suporte a websockets
    "0rtt"                   = "off"  # 0-RTT (Round Tripe Time -> não espera o handshake terminar numa segunda chamada -> desligado por padrão) 
    min_tls_version          = "1.2"  # TLS mínimo aceito
    ssl                      = "full" # modo SSL com origem (use "strict" se tiver cert válido na origem)
    early_hints              = "on"   #  browser começa a precarregar assets antes mesmo da resposta final → reduz LCP (Large Contentful Paint)
    speed_brain              = "on"   # pré-carrega links de outras páginas para o usuário (assim as páginas abrem quase instantaneamente)
  }
}

# um recurso por setting
resource "cloudflare_zone_setting" "zone" {
  for_each   = local.zone_settings
  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}

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

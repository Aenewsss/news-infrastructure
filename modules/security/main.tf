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
        },
        "Content-Security-Policy" = {
          operation = "set"
          value     = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://static.cloudflareinsights.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' https:; frame-ancestors 'none'; base-uri 'self';"
        }
      }
    }
  }]
}
#############################
############ WAF ############
#############################

# Detecta se já existe ruleset MANAGED na zona
data "cloudflare_rulesets" "all" {
  zone_id = var.zone_id
}

locals {
  existing_waf_managed = [
    for r in data.cloudflare_rulesets.all.result :
    r if try(r.phase, "") == "http_request_firewall_managed" && try(r.kind, "") == "zone"
  ]
  has_waf_managed = length(local.existing_waf_managed) > 0
}

# Só cria SE ainda não houver um ruleset managed na fase
# Desligado, pois não pode ser usado no plano free
# resource "cloudflare_ruleset" "waf_managed" {
#   count   = local.has_waf_managed ? 0 : 1
#   zone_id = var.zone_id
#   kind    = "zone"
#   name    = "WAF - Managed Rules"
#   phase   = "http_request_firewall_managed"

#   rules = [{
#     expression  = "true"
#     enabled     = true
#     description = "Attach Cloudflare Managed WAF"
#     action      = "execute"

#     action_parameters = {
#       id = var.managed_ruleset_id
#     }
#   }]
# }

#############################
####### RATE LIMITING #######
#############################

resource "cloudflare_ruleset" "rate_limits" {
  zone_id = var.zone_id
  name    = "Rate limiting rules"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    # {
    #   enabled     = true
    #   description = "API reads: 200 rpm por IP"
    #   expression  = "(starts_with(http.request.uri.path, \"/api/\") and (http.request.method in {\"GET\" \"HEAD\"}))"
    #   action      = "managed_challenge"

    #   ratelimit = {
    #     characteristics     = ["ip.src", "cf.colo.id"]
    #     period              = 60 # segundos
    #     requests_per_period = 200
    #     mitigation_timeout  = 600 # segundos (10 min)
    #     action              = "managed_challenge"
    #   }
    # },
    # {
    #   enabled     = true
    #   description = "API writes: 30 rpm por IP"
    #   expression  = "(starts_with(http.request.uri.path, \"/api/\") and (http.request.method in {\"POST\" \"PUT\" \"PATCH\" \"DELETE\"}))"
    #   action      = "managed_challenge"
    #   ratelimit = {
    #     characteristics     = ["ip.src", "cf.colo.id"]
    #     period              = 60
    #     requests_per_period = 30
    #     mitigation_timeout  = 600
    #     action              = "managed_challenge"
    #   }
    # },
    {
      enabled     = true
      description = "Admin: 60 rpm por IP"
      expression  = "(starts_with(http.request.uri.path, \"/admin\"))"
      action      = "block"
      # action      = "managed_challenge" é o ideal, mas o plano gratuito não cobre
      ratelimit = {
        # period            = 60 é o ideal, mas o plano gratuito não cobre
        # requests_per_period = 60 é o ideal, mas o plano gratuito não cobre
        # mitigation_timeout  = 600 é o ideal, mas o plano gratuito não cobre
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 10
        requests_per_period = 10
        mitigation_timeout  = 10
        action              = "managed_challenge"
      }
    }
  ]
}

#############################
####### Access Rules ########
#############################

# Fase de firewall custom para regras do seu domínio
resource "cloudflare_ruleset" "firewall_custom" {
  zone_id = var.zone_id
  kind    = "zone"
  name    = "Firewall custom"
  phase   = "http_request_firewall_custom"

  rules = [{
    enabled     = true
    description = "Admin: managed challenge para métodos não-GET"
    expression  = "(http.host eq \"${var.domain}\") and starts_with(http.request.uri.path, \"/admin\") and http.request.method ne \"GET\""
    action      = "managed_challenge"
    },
    {
      enabled     = true
      description = "Desafiar tráfego de alto risco"
      # Mantém bots bons livres; desafia ameaça alta
      expression = "(not cf.client.bot) and (cf.threat_score >= 40)"
      action     = "managed_challenge"
    },
    {
      enabled     = true
      description = "Permitir bots conhecidos"
      expression  = "cf.client.bot"
      action      = "skip"
      action_parameters = {
        # Evita que regras posteriores deste MESMO ruleset sejam aplicadas
        ruleset = "current"

        # E também pula fases/products específicos (WAF gerenciado e Rate Limiting)
        phases = ["http_request_firewall_managed", "http_ratelimit"]
        # ou, alternativamente (dependendo do suporte da sua conta):
        # products = ["waf", "ratelimit"]
      }
    }
  ]
}

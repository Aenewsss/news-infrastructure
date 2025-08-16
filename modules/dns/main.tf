data "cloudflare_dns_records" "existing_www" {
  zone_id = var.zone_id
  name = {
    exact = "wwa.${var.zone_name}"
  }
  type = "CNAME"
}

data "cloudflare_rulesets" "zone_all" {
  zone_id = var.zone_id
}

locals {
  has_dns_record = length(data.cloudflare_dns_records.existing_www.result) > 0
  redirect_rulesets = [
    for r in data.cloudflare_rulesets.zone_all.result :
    r if try(r.phase, "") == "http_request_dynamic_redirect" && try(r.kind, "") == "zone"
  ]
  has_redirect_ruleset = length(local.redirect_rulesets) > 0
}

resource "cloudflare_dns_record" "www" {
  count   = local.has_dns_record ? 0 : 1
  zone_id = var.zone_id
  # name    = "www"
  name    = "wwa"
  type    = "CNAME"
  content = "${var.pages_project_name}.pages.dev"
  proxied = true
  ttl     = 1
}

# Redirect apex -> www (transform/redirect rule)
resource "cloudflare_ruleset" "redirect_apex_to_www" {
  count = local.has_redirect_ruleset ? 0 : 1

  kind    = "zone"
  name    = "Redirect apex -> wwa"
  phase   = "http_request_dynamic_redirect"
  zone_id = var.zone_id

  rules = [{
    enabled     = true
    description = "301 apex to wwa"
    expression  = "(http.host eq \"${var.zone_name}\")"
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code = 301
        target_url = {
          expression = "concat(\"https://wwa.${var.zone_name}\", http.request.uri.path)"
        }
      }
    }
  }]
}

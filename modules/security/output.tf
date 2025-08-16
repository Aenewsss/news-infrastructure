output "waf_managed_ruleset_existing_id" {
  value       = local.has_waf_managed ? local.existing_waf_managed[0].id : null
  description = "Se já havia WAF managed, este é o ID existente."
}

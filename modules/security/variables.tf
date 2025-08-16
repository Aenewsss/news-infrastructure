variable "zone_id" {
  type = string
}

variable "managed_ruleset_id" {
  type        = string
  description = "ID do Zone Level Managed Ruleset"
  default     = "efb7b8c949ac4650a09736fc376e9aee" # ID padrão conhecido para o 'Zone Level Managed Ruleset' (pode manter ou sobrescrever)
}

variable "domain" {
  type = string
}
variable "neon_api_key" {
  type        = string
  description = "API key do Neon (Settings → API Keys)."
  sensitive   = true
}

variable "project_name" {
  type        = string
  description = "Nome do projeto no Neon."
}

variable "region" {
  type        = string
  description = "Região do Neon (ex.: aws-us-east-1, aws-eu-central-1...)."
  default     = "aws-us-east-1"
}

variable "pg_version" {
  type        = number
  description = "Versão do Postgres."
  default     = 15
}

variable "branch_name" {
  type        = string
  description = "Nome do branch principal (prod)."
  default     = "main"
}

variable "db_name" {
  type        = string
  description = "Nome do database da aplicação."
}

variable "app_role_name" {
  type    = string
  default = "app_user"
}

variable "readonly_role_name" {
  type    = string
  default = "read_user"
}

variable "autosuspend_seconds" {
  type        = number
  description = "Idle timeout para suspender compute (economia)."
  default     = 300
}

variable "owner_name" {
  type = string
  default = "neondb_owner"
}
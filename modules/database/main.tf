data "neon_branches" "existing_branch" {
  project_id = neon_project.this.id
}

locals {
  existing_branch = [
    for b in data.neon_branches.existing_branch.branches :
    b if try(b.name, "") == var.branch_name
  ]
  has_branch = length(local.existing_branch) > 0
  branch_id  = local.has_branch ? local.existing_branch[0].id : neon_branch.prod[0].id
}

# 1) Liste os endpoints do branch
data "neon_branch_endpoints" "branch_eps" {
  project_id = neon_project.this.id
  branch_id  = local.branch_id # use seu local/var aqui
}

# 2) Filtre o read_write existente (se houver)
locals {
  existing_rw = [
    for ep in try(data.neon_branch_endpoints.branch_eps.endpoints, []) :
    ep if try(ep.type, "") == "read_write"
  ]
  has_rw_endpoint = length(local.existing_rw) > 0
}

# Projeto
resource "neon_project" "this" {
  name                      = var.project_name
  region_id                 = var.region
  pg_version                = var.pg_version
  history_retention_seconds = 21600
}

# Branch principal (prod)
resource "neon_branch" "prod" {
  count      = local.has_branch ? 0 : 1
  project_id = neon_project.this.id
  name       = var.branch_name
}

# Endpoint (compute) de leitura/escrita do branch
resource "neon_endpoint" "prod_rw" {
  count                   = local.has_rw_endpoint ? 0 : 1
  project_id              = neon_project.this.id
  branch_id               = local.branch_id
  type                    = "read_write"
  suspend_timeout_seconds = var.autosuspend_seconds
}

locals {
  endpoint_id   = local.has_rw_endpoint ? local.existing_rw[0].id : neon_endpoint.prod_rw[0].id
  endpoint_host = local.has_rw_endpoint ? local.existing_rw[0].host : neon_endpoint.prod_rw[0].host
}


# Database
resource "neon_database" "app" {
  project_id = neon_project.this.id
  branch_id  = local.branch_id
  name       = var.db_name
  owner_name = var.owner_name
}

# Roles (o provider pode gerar senha se não passar)
resource "neon_role" "app" {
  project_id = neon_project.this.id
  branch_id  = local.branch_id
  name       = var.app_role_name
  # password = var.app_role_password  # opcional; senão, Neon gera e expõe como attribute
}

resource "neon_role" "readonly" {
  project_id = neon_project.this.id
  branch_id  = local.branch_id
  name       = var.readonly_role_name
  # password = var.readonly_role_password
}

# Para construir URIs de conexão, usamos os atributos do endpoint + roles
locals {
  host = local.endpoint_host
  port = 5432

  app_user     = neon_role.app.name
  app_password = neon_role.app.password
  ro_user      = neon_role.readonly.name
  ro_password  = neon_role.readonly.password
}

# Strings de conexão (Postgres URI)
# Obs.: se quiser sslmode=verify-full, adicione ao final do URI.
# Neon já usa TLS por padrão.
locals {
  uri_app = "postgresql://${local.app_user}:${local.app_password}@${local.host}:${local.port}/${neon_database.app.name}"
  uri_ro  = "postgresql://${local.ro_user}:${local.ro_password}@${local.host}:${local.port}/${neon_database.app.name}"
}

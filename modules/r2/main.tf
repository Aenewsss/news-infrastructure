resource "cloudflare_r2_bucket" "media" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = "WNAM" # ajuste se quiser (WNAM/ENAM/WEUR/APAC/etc.)
  # jurisdiction = "EU" # opcional, se precisar residência de dados
}

# CORS do bucket (para upload direto do browser para o Worker/rota)
resource "cloudflare_r2_bucket_cors" "media_cors" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.media.name

  rules = [{
    allowed = {
      headers = var.cors_allowed_headers
      methods = var.cors_allowed_methods
      origins = var.cors_allowed_origins
    }
    max_age_seconds = var.cors_max_age
  }]
}

# lifecycle (ex.: expirar versões antigas, arquivar temporários)
resource "cloudflare_r2_bucket_lifecycle" "media_lifecycle" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.media.name
  rules = [{
    id         = "expire-tmp"
    enabled    = true
    conditions = { prefix = "tmp/" }

    # 1) Transiciona de classe após 1 dia
    storage_class_transitions = [{
      storage_class = "InfrequentAccess"
      condition = {
        max_age = 1
        type = "Age"
      }
    }]

    # 2) Deletar após 7 dias
    delete_objects_transition = {
      condition = {
        max_age = 7
        type = "Age"
      }
    }
  }]
}

resource "upstash_redis_database" "redis" {
  database_name  = var.upstash_database_name
  region         = "global"
  primary_region = var.upstash_database_region
  tls            = true

  lifecycle {
    prevent_destroy = true
  }
}

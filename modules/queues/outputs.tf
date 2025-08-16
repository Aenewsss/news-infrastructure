output "upstash_rest_url" {
  value = upstash_redis_database.redis.endpoint
}

output "upstash_rest_token" {
  value = upstash_redis_database.redis.rest_token
}

variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "queue_name" {
  type    = string
  default = "news-flush"
}

variable "consumer_name" {
  type    = string
  default = "flush-consumer"
}

variable "producer_name" {
  type    = string
  default = "flush-producer"
}

variable "producer_route" {
  type = string
  # ex: "news.seudominio.com/api/track*"
  default = ""
}

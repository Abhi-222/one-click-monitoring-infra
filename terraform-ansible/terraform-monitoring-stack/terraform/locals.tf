locals {
  env_prefix  = "monitoring-${var.environment}"
  common_tags = merge(var.tags, { Environment = var.environment })
}

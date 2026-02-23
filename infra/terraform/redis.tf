resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${replace(local.name_prefix, "-", "")}redis"
  description                = "${local.name_prefix} redis"
  node_type                  = "cache.t3.micro"
  engine                     = "redis"
  engine_version             = "7.1"
  num_cache_clusters         = 1
  parameter_group_name       = "default.redis7"
  port                       = 6379
  automatic_failover_enabled = false
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]

  tags = local.common_tags
}


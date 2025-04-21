module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  port = 6378

  replication_group_id = "${var.project_name}-redis"
  cluster_mode_enabled = true
  cluster_mode         = "enabled"

  apply_immediately = true

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.r7g.large"

  vpc_id = aws_vpc.this.id
  security_group_rules = {
    ingress_vpc = {
      from_port   = 6378
      to_port     = 6378
      description = "VPC traffic"
      cidr_ipv4   = local.vpc_cidr
    }
  }

  create_subnet_group = false
  subnet_group_name   = local.vpc_elasticache_subnet_group_names[0]

  create_parameter_group  = true
  parameter_group_family  = "redis7"
  num_node_groups         = 3
  replicas_per_node_group = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true
  snapshot_retention_limit   = 7

  at_rest_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  log_delivery_configuration = {
    slow-log = {
      cloudwatch_log_group_name = "${var.project_name}-redis/slowlog"
      destination_type          = "cloudwatch-logs"
      log_format                = "json"
    }
    engine-log = {
      cloudwatch_log_group_name = "${var.project_name}-redis/enginelog"
      destination_type          = "cloudwatch-logs"
      log_format                = "json"
    }
  }
}

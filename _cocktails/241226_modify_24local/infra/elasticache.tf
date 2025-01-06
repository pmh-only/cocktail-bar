module "elasticache_primary" {
  source = "terraform-aws-modules/elasticache/aws"

  replication_group_id = "${var.project_name}-redis-cluster"
  port                 = 6378
  cluster_mode_enabled = true
  cluster_mode         = "enabled"

  engine         = "redis"
  engine_version = "7.0"
  node_type      = "cache.t4g.small"

  vpc_id = module.vpc.vpc_id
  security_group_rules = {
    ingress_vpc = {
      description = "VPC traffic"
      cidr_ipv4   = module.vpc.vpc_cidr_block
      from_port   = 6378
      to_port     = 6378
    }
  }

  subnet_ids = module.vpc.intra_subnets

  create_parameter_group  = true
  parameter_group_family  = "redis7"
  num_node_groups         = 3
  replicas_per_node_group = 2

  multi_az_enabled         = true
  snapshot_retention_limit = 7

  log_delivery_configuration = {
    "slow-log" : {
      "cloudwatch_log_group_name" : "${var.project_name}-redis/slowlog",
      "destination_type" : "cloudwatch-logs",
      "log_format" : "json"
    },
    "engine-log" : {
      "cloudwatch_log_group_name" : "${var.project_name}-redis/enginelog",
      "destination_type" : "cloudwatch-logs",
      "log_format" : "json"
    }
  }
}

module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  port = 6378

  # !! For Secondary Cluster:
  # we don't know replication group id exactly before creation. (cuz aws generates prefix automatically)
  # so, apply with create=false first. When you know the group id, change create=true and replace id placeholder
  # -----------
  create                      = true
  global_replication_group_id = "lfqnh-project-ap-redis"

  create_primary_global_replication_group   = false
  create_secondary_global_replication_group = true

  replication_group_id = "${var.project_name}-redis"
  cluster_mode_enabled = true
  cluster_mode         = "enabled"

  apply_immediately = true

  engine         = "redis"
  engine_version = "7.1"

  vpc_id = aws_vpc.this.id
  security_group_rules = {
    ingress_vpc = {
      from_port   = 6378
      to_port     = 6378
      description = "VPC traffic"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  create_subnet_group = false
  subnet_group_name   = local.vpc_elasticache_subnet_group_names[0]

  create_parameter_group  = true
  parameter_group_family  = "redis7"
  replicas_per_node_group = 1

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

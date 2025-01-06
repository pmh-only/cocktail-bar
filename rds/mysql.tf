module "db" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name           = "${var.project_name}-rds"
  engine         = "mysql"
  engine_version = "8.0"

  vpc_id                 = module.vpc.vpc_id
  subnets                = (length(module.vpc.intra_subnets) > 0) ? module.vpc.intra_subnets : module.vpc.private_subnets
  db_subnet_group_name   = "${var.project_name}-subnets"
  create_db_subnet_group = true
  port                   = 3307

  security_group_rules = [
    {
      type                     = "ingress"
      security_group_id        = module.db.security_group_id
      source_security_group_id = aws_security_group.bastion.id
      from_port                = 3307
      to_port                  = 3307
      protocol                 = "tcp"
    }
  ]

  master_username                                        = "adminuser"
  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = 1

  enabled_cloudwatch_logs_exports        = ["audit", "error", "general", "slowquery"]
  cloudwatch_log_group_retention_in_days = 7

  cluster_performance_insights_enabled          = true
  cluster_performance_insights_retention_period = 7

  availability_zones        = module.vpc.azs
  db_cluster_instance_class = "db.m5d.large"
  storage_type              = "io2"
  iops                      = 3000
  allocated_storage         = 100

  iam_database_authentication_enabled = true

  skip_final_snapshot = true
  deletion_protection = true
  apply_immediately   = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  backup_retention_period               = 7

  create_monitoring_role = true
  monitoring_interval    = 60

  create_db_cluster_parameter_group           = true
  create_db_parameter_group                   = true
  db_cluster_parameter_group_family           = "mysql8.0"
  db_parameter_group_family                   = "mysql8.0"
  db_cluster_db_instance_parameter_group_name = "mysql8.0"

  autoscaling_enabled      = false
  autoscaling_max_capacity = 6
  autoscaling_min_capacity = 3
}

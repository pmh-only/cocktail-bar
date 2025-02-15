resource "aws_rds_global_cluster" "this" {
  # !! Change me
  global_cluster_identifier = "project-rds"

  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.05.2"
  database_name       = "dev"
  storage_encrypted   = true
  deletion_protection = true
}

module "db" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name                      = "${var.project_name}-rds"
  database_name             = aws_rds_global_cluster.this.database_name
  engine                    = aws_rds_global_cluster.this.engine
  engine_version            = aws_rds_global_cluster.this.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  instances = { for i in range(length(local.vpc_azs)) : i => {
    availability_zone = local.vpc_azs[i]
    instance_class    = "db.r6g.large"
  } }

  port = 3307

  vpc_id               = local.vpc_id
  availability_zones   = local.vpc_azs
  db_subnet_group_name = local.vpc_rds_subnet_group_names[0]
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = ["10.0.0.0/8"]
    }
  }

  manage_master_user_password = false
  master_username             = "myadmin"
  master_password             = "admin123!!"

  deletion_protection                 = true
  skip_final_snapshot                 = true
  apply_immediately                   = true
  kms_key_id                          = aws_kms_key.primary.arn
  iam_database_authentication_enabled = true

  cluster_performance_insights_enabled          = true
  cluster_performance_insights_retention_period = 7

  backup_retention_period                = 7
  performance_insights_enabled           = true
  performance_insights_retention_period  = 7
  create_monitoring_role                 = true
  monitoring_interval                    = 30
  cloudwatch_log_group_retention_in_days = 7
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group           = true
  create_db_parameter_group                   = true
  db_cluster_parameter_group_family           = "aurora-mysql8.0"
  db_parameter_group_family                   = "aurora-mysql8.0"
  db_cluster_db_instance_parameter_group_name = "aurora-mysql8.0"
}

data "aws_iam_policy_document" "rds" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.caller.account_id}:root",
        data.aws_caller_identity.caller.arn,
      ]
    }
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_key" "primary" {
  policy = data.aws_iam_policy_document.rds.json
}


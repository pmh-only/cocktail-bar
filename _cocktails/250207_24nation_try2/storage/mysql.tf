module "aurora_primary" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name           = "wsc2024-db-cluster"
  database_name  = "wsc2024_db"
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.05.2"
  instance_class = "db.t3.medium"
  instances      = { for i in range(2) : i => {} }

  vpc_id               = aws_vpc.this.id
  db_subnet_group_name = "wsc2024-storage-subnets-0"
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  manage_master_user_password = true
  master_username             = "admin"

  deletion_protection = true
  skip_final_snapshot = true
  kms_key_id          = aws_kms_key.primary.arn

  availability_zones = [
    "${var.region}a",
    "${var.region}b"
  ]

  backup_retention_period      = 7
  performance_insights_enabled = false
  monitoring_interval          = 30
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group           = true
  cluster_performance_insights_enabled        = true
  db_cluster_parameter_group_family           = "aurora-mysql8.0"
  db_parameter_group_family                   = "aurora-mysql8.0"
  db_cluster_db_instance_parameter_group_name = "aurora-mysql8.0"
  backtrack_window                            = 259200
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


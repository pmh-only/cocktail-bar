resource "aws_security_group" "rds" {
  name   = "${var.project_name}-sg-rds"
  vpc_id = aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    from_port   = 3307
    to_port     = 3307
    cidr_blocks = [local.vpc_cidr]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier     = "${var.project_name}-rds"
  db_name        = "dev"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r6g.large"

  port = 3307

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = local.vpc_rds_subnet_group_names[0]
  create_db_subnet_group = false
  multi_az               = true

  manage_master_user_password                            = true
  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = 1

  username = "myadmin"
  # password = "admin123!!"

  deletion_protection                 = true
  skip_final_snapshot                 = true
  apply_immediately                   = true
  kms_key_id                          = aws_kms_key.primary.arn
  iam_database_authentication_enabled = true

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

  storage_type          = "io2"
  iops                  = 3000
  allocated_storage     = 100
  max_allocated_storage = 1000
  dedicated_log_volume  = true

  create_db_parameter_group = true
  family                    = "mysql8.0"
  major_engine_version      = "8.0"
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

resource "aws_kms_alias" "primary" {
  name          = "alias/rds/${var.project_name}-rds"
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_db_snapshot" "test" {
  db_instance_identifier = module.db.db_instance_identifier
  db_snapshot_identifier = "${module.db.db_instance_identifier}-init"
}

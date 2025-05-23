module "aurora_secondary" {
  source = "terraform-aws-modules/rds-aurora/aws"

  port = 3307

  name                      = "${var.project_name}-mysql-cluster"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  global_cluster_identifier = "unicorn-mysql"
  instance_class            = "db.r6g.large"
  instances                 = { for i in range(2) : i => {} }

  is_primary_cluster = false

  vpc_id               = aws_vpc.this.id
  db_subnet_group_name = values(aws_db_subnet_group.rds)[0].name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  deletion_protection = true
  skip_final_snapshot = true
  kms_key_id          = aws_kms_key.primary.arn


  availability_zones = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  backup_retention_period      = 7
  performance_insights_enabled = true
  monitoring_interval          = 30
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group           = true
  cluster_performance_insights_enabled        = true
  apply_immediately                           = true
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


resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "${var.project_name}-rds"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  database_name             = "dev"
  storage_encrypted         = true
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-subnets"
  subnet_ids  = module.vpc.intra_subnets
}

module "aurora_primary" {
  source =  "terraform-aws-modules/rds-aurora/aws"

  name                      = "${var.project_name}-ap-rds"
  database_name             = aws_rds_global_cluster.this.database_name
  engine                    = aws_rds_global_cluster.this.engine
  engine_version            = aws_rds_global_cluster.this.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  instance_class            = "db.r6g.large"
  instances                 = { for i in range(2) : i => {} }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = aws_db_subnet_group.this.name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  # Global clusters do not support managed master user password
  manage_master_user_password = false
  master_username           = "admin"
  master_password             = "admin123!!"

  deletion_protection = true
  skip_final_snapshot = true
  kms_key_id = aws_kms_key.primary.arn 

  availability_zones = module.vpc.azs
  backup_retention_period = 7
  performance_insights_enabled = true
  monitoring_interval = 30
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group = true
  cluster_performance_insights_enabled = true

  apply_immediately = true
}

module "aurora_secondary" {
  source =  "terraform-aws-modules/rds-aurora/aws"

  name                      = "${var.project_name}-ap-rds"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  global_cluster_identifier = ""
  instance_class            = "db.r6g.large"
  instances                 = { for i in range(2) : i => {} }

  is_primary_cluster = false

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = aws_db_subnet_group.this.name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  deletion_protection = true
  skip_final_snapshot = true
  kms_key_id = aws_kms_key.primary.arn 

  availability_zones = module.vpc.azs
  backup_retention_period = 7
  performance_insights_enabled = true
  monitoring_interval = 30
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group = true
  cluster_performance_insights_enabled = true
  apply_immediately = true
  db_cluster_parameter_group_family = "aurora-mysql8.0"
  db_parameter_group_family = "aurora-mysql8.0"
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


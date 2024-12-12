resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-subnets"
  subnet_ids  = module.vpc.intra_subnets
}

module "aurora_secondary" {
  source = "terraform-aws-modules/rds-aurora/aws"

  is_primary_cluster = false

  name                      = "${var.project_name}-rds"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  global_cluster_identifier = "wsi-rds"
  source_region             = "us-east-1"
  instance_class            = "db.r6g.large"
  instances                 = { for i in range(2) : i => {} }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = aws_db_subnet_group.this.name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  master_password = "admin123!!"
  deletion_protection = true
  skip_final_snapshot = true
  kms_key_id = aws_kms_key.primary.arn 
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


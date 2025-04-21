###############################
# Security Group for DocumentDB
###############################

resource "aws_security_group" "docdb" {
  name   = "${var.project_name}-sg-docdb"
  vpc_id = aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    from_port   = 27018
    to_port     = 27018
    cidr_blocks = [local.vpc_cidr]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

###########################################
# DocumentDB Cluster and Cluster Instances
###########################################

resource "aws_docdb_cluster" "this" {
  global_cluster_identifier = "project-docdb"

  cluster_identifier = "${var.project_name}-docdb"
  engine             = "docdb"
  engine_version     = "5.0.0"

  port = 27018

  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  db_subnet_group_name    = local.vpc_rds_subnet_group_names[0]
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.docdb.arn

  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.docdb.name

  enabled_cloudwatch_logs_exports = [
    "audit",
    "profiler"
  ]

  apply_immediately   = true
  deletion_protection = true
  skip_final_snapshot = true
}

# For high availability, create more than one instance.
# Here we create 2 instances (spread across AZs) to mimic multi-AZ.
resource "aws_docdb_cluster_instance" "this" {
  count              = 2
  cluster_identifier = aws_docdb_cluster.this.id
  identifier         = "${var.project_name}-docdb-${count.index}"
  instance_class     = "db.r6g.large"

  enable_performance_insights = true
}

#############################
# DocumentDB Cluster Snapshot
#############################

resource "aws_docdb_cluster_snapshot" "test" {
  db_cluster_identifier          = aws_docdb_cluster.this.id
  db_cluster_snapshot_identifier = "${aws_docdb_cluster.this.id}-init"
}

#############################
# DocumentDB cluster parameter
#############################

resource "aws_docdb_cluster_parameter_group" "docdb" {
  family = "docdb5.0"
  name   = "${var.project_name}-docdb-parameters"

  parameter {
    name  = "audit_logs"
    value = "all"
  }
}

#############################
# KMS Shared key
#############################

resource "aws_kms_key" "docdb" {
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAdministrationOfTheKey",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.caller.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowAWSDocDBToUseTheKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "docdb.amazonaws.com"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      }
    ]
  })
}

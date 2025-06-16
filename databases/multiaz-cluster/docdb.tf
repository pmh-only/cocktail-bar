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
  cluster_identifier = "${var.project_name}-docdb"
  engine             = "docdb"
  engine_version     = "5.0.0"

  port = 27018

  master_username = "myadmin"
  # master_password = "admin123!!"
  manage_master_user_password = true


  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  db_subnet_group_name    = local.vpc_rds_subnet_group_names[0]
  storage_encrypted       = true

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

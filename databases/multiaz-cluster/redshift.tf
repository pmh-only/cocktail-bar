module "redshift" {
  source = "terraform-aws-modules/redshift/aws"

  cluster_identifier    = "${var.project_name}-redshift"
  allow_version_upgrade = true
  node_type             = "ra3.xlplus"
  number_of_nodes       = 2

  ######################################################
  # Multi az only possible in 3-AZs VPC
  ######################################################

  multi_az = true
  # availability_zone_relocation_enabled = true

  port = 5438

  database_name = "dev"

  manage_master_password                            = true
  manage_master_password_rotation                   = true
  master_password_rotation_automatically_after_days = 1

  master_username = "myadmin"
  # master_password = "admin123!!"

  encrypted = true

  create_subnet_group    = false
  enhanced_vpc_routing   = true
  vpc_security_group_ids = [aws_security_group.redshift.id]
  subnet_group_name      = local.vpc_redshift_subnet_group_names[0]

  logging = {
    log_destination_type = "cloudwatch"
    log_exports = [
      "connectionlog",
      "userlog",
      "useractivitylog"
    ]
  }

  create_snapshot_schedule        = true
  use_snapshot_identifier_prefix  = false
  snapshot_schedule_definitions   = ["rate(12 hours)"]
  snapshot_schedule_force_destroy = true

  create_endpoint_access          = true
  endpoint_name                   = "${var.project_name}-endpoint-redshift"
  endpoint_subnet_group_name      = local.vpc_redshift_subnet_group_names[0]
  endpoint_vpc_security_group_ids = [aws_security_group.redshift.id]

  apply_immediately = true
}

resource "aws_redshift_cluster_snapshot" "init" {
  cluster_identifier  = module.redshift.cluster_id
  snapshot_identifier = "${module.redshift.cluster_id}-init"
}

resource "aws_security_group" "redshift" {
  name   = "${var.project_name}-sg-redshift"
  vpc_id = aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    from_port   = 5438
    to_port     = 5438
    cidr_blocks = [local.vpc_cidr]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

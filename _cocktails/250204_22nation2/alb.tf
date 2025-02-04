module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name   = "${var.project_name}-alb"
  vpc_id = aws_vpc.this.id
  subnets = [
    aws_subnet.this[local.all_subnets[0].key].id,
    aws_subnet.this[local.all_subnets[1].key].id,
    aws_subnet.this[local.all_subnets[2].key].id
  ]

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
  }

  connection_logs = {
    bucket = module.log_bucket.s3_bucket_id
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "tg1"
      }
    }
  }

  target_groups = {
    tg1 = {
      name              = "${var.project_name}-tg1"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
    }
    tg2 = {
      name              = "${var.project_name}-tg2"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
    }
  }
}

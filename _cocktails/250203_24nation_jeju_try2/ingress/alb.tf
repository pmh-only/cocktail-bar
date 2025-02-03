module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name   = "${var.project_name}-lb"
  vpc_id = aws_vpc.this.id
  subnets = [
    aws_subnet.this[local.all_subnets[0].key].id,
    aws_subnet.this[local.all_subnets[1].key].id,
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

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "forward"
      }
    }
  }

  target_groups = {
    forward = {
      name              = "${var.project_name}-forward"
      create_attachment = false
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
    }
  }
}

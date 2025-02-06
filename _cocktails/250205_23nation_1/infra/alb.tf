locals {
  alb_internal = false
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name     = "${var.project_name}-alb"
  internal = local.alb_internal

  tags = {
    Name = "${var.project_name}-alb"
  }

  # vpc_id  = module.vpc.vpc_id
  # subnets = local.alb_internal ? module.vpc.private_subnets : module.vpc.public_subnets

  # V2
  vpc_id = aws_vpc.this.id
  subnets = [
    for subnet in local.all_subnets :
    aws_subnet.this[subnet.key].id

    if local.alb_internal ? subnet.group.tag_alb_private : subnet.group.tag_alb_public
  ]

  enable_cross_zone_load_balancing = true
  enable_zonal_shift               = true

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
      weighted_forward = {
        target_groups = [
          {
            target_group_key = "stresstg1"
            weight           = 1
          },
          {
            target_group_key = "producttg1"
            weight           = 1
          }
        ]
      }
    }
  }

  target_groups = {
    stresstg1 = {
      name              = "${var.project_name}-stress-tg1"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    stresstg2 = {
      name              = "${var.project_name}-stress-tg2"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    producttg1 = {
      name              = "${var.project_name}-product-tg1"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    producttg2 = {
      name              = "${var.project_name}-product-tg2"
      create_attachment = false
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }
}

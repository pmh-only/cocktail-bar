locals {
  alb_internal = false
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name     = "${var.project_name}-alb"
  internal = local.alb_internal

  vpc_id = aws_vpc.this.id
  subnets = [
    for subnet in local.all_subnets :
    aws_subnet.this[subnet.key].id

    if local.alb_internal ? subnet.group.tag_alb_private : subnet.group.tag_alb_public
  ]

  enable_cross_zone_load_balancing = true
  enable_zonal_shift               = true
  client_keep_alive                = 60

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

      fixed_response = {
        content_type = "text/plain"
        message_body = "404 Not Found"
        status_code  = "404"
      }

      rules = {
        status = {
          priority = 100
          actions = [
            {
              type = "weighted-forward"
              target_groups = [
                {
                  target_group_key = "status-blue"
                  weight           = 100
                },
                {
                  target_group_key = "status-green"
                  weight           = 0
                }
              ]
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/v1/status"]
            }
          }]
        }

        stress = {
          priority = 90
          actions = [
            {
              type = "weighted-forward"
              target_groups = [
                {
                  target_group_key = "stress-blue"
                  weight           = 100
                },
                {
                  target_group_key = "stress-green"
                  weight           = 0
                }
              ]
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/v1/stress"]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    stress-blue = {
      name              = "${var.project_name}-stress-blue"
      create_attachment = false
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/healthcheck"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }

    stress-green = {
      name              = "${var.project_name}-stress-green"
      create_attachment = false
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/healthcheck"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }

    status-blue = {
      name              = "${var.project_name}-status-blue"
      create_attachment = false
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/healthcheck"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200"
      }
    }

    status-green = {
      name              = "${var.project_name}-status-green"
      create_attachment = false
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"

      deregistration_delay              = 60
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/healthcheck"
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

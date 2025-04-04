# replace all name - ecs_service

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  force_new_deployment = true
  force_delete         = true

  name        = "${var.project_name}-myapp"
  cluster_arn = module.ecs.cluster_arn

  deployment_controller = {
    type = "ECS" # or CODE_DEPLOY
  }

  enable_execute_command = true

  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    EC2 = {
      capacity_provider = module.ecs.autoscaling_capacity_providers["EC2"].name
      weight            = 1
      base              = 1
    }
  }

  tasks_iam_role_policies = {
    CloudWatchFullAccess     = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
    AWSAppMeshEnvoyAccess    = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
    AWSXRayDaemonWriteAccess = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  }

  task_exec_iam_role_policies = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  cpu    = 256
  memory = 256

  # cpuArchitecture
  # Valid Values: X86_64 | ARM64

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    myapp = {
      essential = true
      image     = "ghcr.io/pmh-only/the-biggie:latest"

      dependencies = [{
        condition     = "HEALTHY"
        containerName = "envoy"
      }]

      health_check = {
        command  = ["CMD-SHELL", "curl -f http://localhost:8080/healthcheck || exit 1"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      # secrets = [{
      #   name      = "MYSQL_DBINFO"
      #   valueFrom = "arn:aws:secretsmanager:ap-northeast-2:648911607072:secret:project-rds-r5wn4n"
      # }]

      port_mappings = [
        {
          name          = "myapp"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/project-myapp"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }

      # log_configuration = {
      #   logDriver = "awsfirelens"
      #   options   = {}
      # }

      # log_configuration = {
      #   logDriver = "fluentd"
      #   options = {
      #     fluentd-address = "unix:///var/run/fluent.sock",
      #     tag             = "app.{{.FullID}}"
      #   }
      # }

      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false
    }

    # log_router = {
    #   essential = true
    #   image     = "009160052643.dkr.ecr.${var.region}.amazonaws.com/baseflue:latest"

    #   environment = [
    #     {
    #       name = "CONFIG",
    #       value = base64encode(<<-EOF
    #         [SERVICE]
    #           Flush           1
    #           Daemon          off
    #           Log_Level       debug
    #           Parsers_File    /parsers.conf

    #         # [FILTER]
    #         #   Name parser
    #         #   Match *
    #         #   Key_Name log
    #         #   Parser custom
    #         #   Reserve_Data On

    #         [OUTPUT]
    #           Name cloudwatch
    #           Match *
    #           region ${var.region}
    #           log_group_name /aws/ecs/${local.ecs_cluster_name}/myapp
    #           log_stream_name $${TASK_ID}
    #           auto_create_group true
    #         EOF
    #       )
    #     },
    #     {
    #       name = "PARSERS",
    #       value = base64encode(<<-EOF
    #           [PARSER]
    #             Name custom
    #             Format regex
    #             Regex ^(?<remote_addr>.*) - - \[(?<time>.*)\] "(?<method>.*) (?<path>.*) (?<protocol>.*)" (?<status_code>.*) (?<latency>.*) "-" "(?<user_agent>.*)" "-"$
    #             Time_Key time
    #             Time_Format %d/%b/%Y:%H:%M:%S %z
    #             Time_Keep On
    #         EOF
    #       )
    #     }
    #  ]

    #   log_configuration = {
    #     logDriver = "awslogs"
    #     options = {
    #       awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/myapp-logroute"
    #       awslogs-region        = var.region
    #       awslogs-stream-prefix = "ecs"
    #       awslogs-create-group  = "true"
    #     }
    #   }

    #   firelens_configuration = {
    #     type = "fluentbit"
    #     options = {
    #       config-file-type  = "file"
    #       config-file-value = "/config.conf"
    #     }
    #   }

    #   create_cloudwatch_log_group = false
    #   readonly_root_filesystem = false
    # }

    debug = {
      essential = false
      image     = "public.ecr.aws/docker/library/alpine:latest"
      command   = ["/bin/sleep", "infinity"]

      health_check = {
        command  = ["CMD-SHELL", "exit 0"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      enable_cloudwatch_logging = false
      readonly_root_filesystem  = false
    }

    xray = {
      essential = true
      user      = 1337

      image = "public.ecr.aws/xray/aws-xray-daemon"

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/project-myapp/xray"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }

      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false
    }

    envoy = {
      essential = true
      user      = 1337

      image = "840364872350.dkr.ecr.${var.region}.amazonaws.com/aws-appmesh-envoy:v1.29.12.1-prod"
      dependencies = [{
        condition     = "START"
        containerName = "xray"
      }]

      health_check = {
        command  = ["CMD-SHELL", "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"]
        interval = 5
        timeout  = 5
        retries  = 10
      }

      environment = [
        { name = "ENVOY_LOG_LEVEL", value = "debug" },
        { name = "ENABLE_ENVOY_XRAY_TRACING", value = "1" },
        { name = "ENABLE_ENVOY_STATS_TAGS", value = "1" },
        { name = "ENABLE_ENVOY_DOG_STATSD", value = "1" },
        {
          name  = "APPMESH_RESOURCE_ARN",
          value = aws_appmesh_virtual_node.ecs_service.arn
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/project-myapp/envoy"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }

      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups.myapp.arn
      container_name   = "myapp"
      container_port   = 8080
    }
  }

  subnet_ids = [for subnet in local.ecs_cluster_subnets : aws_subnet.this[subnet.key].id]

  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ordered_placement_strategy = [
    {
      field = "attribute:ecs.availability-zone"
      type  = "spread"
    }
  ]

  desired_count            = 2
  autoscaling_max_capacity = 64
  autoscaling_min_capacity = 2
  autoscaling_policies = {
    high = {
      policy_type = "StepScaling"
      step_scaling_policy_configuration = {
        adjustment_type         = "ChangeInCapacity"
        cooldown                = 0
        metric_aggregation_type = "Average"

        step_adjustment = [
          {
            scaling_adjustment          = 2
            metric_interval_upper_bound = 90 - 80
          },
          {
            scaling_adjustment          = 4
            metric_interval_lower_bound = 90 - 80
          }
        ]
      }
    }
    low = {
      policy_type = "StepScaling"
      step_scaling_policy_configuration = {
        adjustment_type         = "ChangeInCapacity"
        cooldown                = 60
        metric_aggregation_type = "Average"

        step_adjustment = [
          {
            scaling_adjustment          = -1
            metric_interval_lower_bound = 50 - 65
          },
          {
            scaling_adjustment          = -2
            metric_interval_upper_bound = 50 - 65
            metric_interval_lower_bound = 25 - 65
          },
          {
            scaling_adjustment          = -4
            metric_interval_upper_bound = 25 - 65
          }
        ]
      }
    }
  }

  service_registries = {
    registry_arn = aws_service_discovery_service.ecs_service.arn
  }

  proxy_configuration = {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = "8080"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_high" {
  alarm_name          = "ecs_service_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80

  metric_query {
    id          = "e1"
    expression  = "MAX([m1,m2])"
    label       = "MAX(CPUUtilization, MemoryUtilization)"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = 60
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = module.ecs_service.name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = 60
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = module.ecs_service.name
      }
    }
  }

  alarm_actions = [module.ecs_service.autoscaling_policies.high.arn]
}


resource "aws_cloudwatch_metric_alarm" "ecs_service_low" {
  alarm_name          = "ecs_service_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 65

  metric_query {
    id          = "e1"
    expression  = "MAX([m1,m2])"
    label       = "MAX(CPUUtilization, MemoryUtilization)"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = 60
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = module.ecs_service.name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = 60
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = module.ecs_service.name
      }
    }
  }

  alarm_actions = [module.ecs_service.autoscaling_policies.low.arn]
}

resource "aws_appmesh_virtual_service" "ecs_service" {
  name      = "myapp.${var.project_name}.local"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.ecs_service.name
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "ecs_service" {
  name      = "${var.project_name}-myapp"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    backend {
      virtual_service {
        virtual_service_name = "myapp2.${var.project_name}.local"
      }
    }

    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }

      health_check {
        protocol            = "http"
        path                = "/healthcheck"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        service_name   = aws_service_discovery_service.ecs_service.name
        namespace_name = aws_service_discovery_private_dns_namespace.example.name
      }
    }
  }
}

resource "aws_service_discovery_service" "ecs_service" {
  name = "myapp"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id

    dns_records {
      type = "A"
      ttl  = 10
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

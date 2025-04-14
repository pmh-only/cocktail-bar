# replace all name - product

module "product" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  force_new_deployment = true
  force_delete         = true

  name        = "product-svc"
  family = "product-td"
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
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    AmazonDynamoDBFullAccess = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    AWSKeyManagementServicePowerUser = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
  }

  task_exec_iam_role_policies = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  cpu    = 256
  memory = 256

  # cpuArchitecture
  # Valid Values: X86_64 | ARM64

  runtime_platform = {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    product = {
      essential = true
      image     = "976139933880.dkr.ecr.ap-northeast-2.amazonaws.com/product:v1.0.0"

      health_check = {
        command  = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
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
          name          = "product"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/${var.project_name}/ecs/product"
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

    debug = {
      essential = false
      image     = "public.ecr.aws/docker/library/alpine:latest"
      command   = ["/bin/sleep", "infinity"]

      dependencies = [{
        condition     = "HEALTHY"
        containerName = "product"
      }]

      health_check = {
        command  = ["CMD-SHELL", "exit 0"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      enable_cloudwatch_logging = false
      readonly_root_filesystem  = false
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
  }

  # load_balancer = {
  #   service = {
  #     target_group_arn = module.alb.target_groups.product.arn
  #     container_name   = "product"
  #     container_port   = 8080
  #   }
  # }

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
    },
    {
      field = "memory"
      type  = "binpack"
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
            metric_interval_upper_bound = 90 - 8080
          },
          {
            scaling_adjustment          = 4
            metric_interval_lower_bound = 90 - 8080
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

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.example.arn
    service = {
      client_alias = {
        dns_name = "product"
        port = 80
      }
      port_name = "product"
    }

    log_configuration = {
      log_driver = "awslogs"
      options = {
        awslogs-group         = "/${var.project_name}/ecs/product/serviceconnect"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
        awslogs-create-group  = "true"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "product_high" {
  alarm_name          = "product_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 8080

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
        ServiceName = module.product.name
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
        ServiceName = module.product.name
      }
    }
  }

  alarm_actions = [module.product.autoscaling_policies.high.arn]
}


resource "aws_cloudwatch_metric_alarm" "product_low" {
  alarm_name          = "product_low"
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
        ServiceName = module.product.name
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
        ServiceName = module.product.name
      }
    }
  }

  alarm_actions = [module.product.autoscaling_policies.low.arn]
}

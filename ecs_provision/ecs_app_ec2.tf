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
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  task_exec_iam_role_policies = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  cpu    = 128
  memory = 128

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

      # log_configuration = {
      #   logDriver = "awsfirelens"
      #   options   = {}
      # }

      log_configuration = {
        logDriver = "fluentd"
        options = {
          fluentd-address = "unix:///var/run/fluent.sock",
          tag             = "app.{{.FullID}}"
        }
      }

      readonly_root_filesystem = false
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
  #     ]

  #     log_configuration = {
  #       logDriver = "awslogs"
  #       options = {
  #         awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/myapp-logroute"
  #         awslogs-region        = var.region
  #         awslogs-stream-prefix = "ecs"
  #         awslogs-create-group  = "true"
  #       }
  #     }

  #     firelens_configuration = {
  #       type = "fluentbit"
  #       options = {
  #         config-file-type  = "file"
  #         config-file-value = "/config.conf"
  #       }
  #     }

  #     readonly_root_filesystem = false
  #   }
  # }

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
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        scale_in_cooldown  = 60
        scale_out_cooldown = 0
        target_value       = 75
      }
    },
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        scale_in_cooldown  = 60
        scale_out_cooldown = 0
        target_value       = 75
      }
    }
  }
}

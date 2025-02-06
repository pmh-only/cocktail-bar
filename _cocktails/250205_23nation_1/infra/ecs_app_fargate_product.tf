module "ecs_service_product" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  force_new_deployment = true
  force_delete         = true

  name        = "product"
  cluster_arn = module.ecs.cluster_arn

  requires_compatibilities = ["FARGATE"]

  tasks_iam_role_policies = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  task_exec_iam_role_policies = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  # CPU value 	    Memory value
  # 256 (.25 vCPU) 	512 MiB, 1 GB, 2 GB
  # 512 (.5 vCPU) 	1 GB, 2 GB, 3 GB, 4 GB
  # 1024 (1 vCPU) 	2 GB, 3 GB, 4 GB, 5 GB, 6 GB, 7 GB, 8 GB
  # 2048 (2 vCPU) 	Between 4 GB and 16 GB in 1 GB increments
  # 4096 (4 vCPU) 	Between 8 GB and 30 GB in 1 GB increments
  # 8192 (8 vCPU)   Between 16 GB and 60 GB in 4 GB increments
  # 16384 (16vCPU)  Between 32 GB and 120 GB in 8 GB increments

  cpu    = 512
  memory = 1024

  # cpuArchitecture
  # Valid Values: X86_64 | ARM64

  runtime_platform = {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    product = {
      cpu       = 256 - 25
      memory    = 1024 - 25
      essential = true
      image     = module.ecr[0].repository_url

      health_check = {
        command  = ["CMD-SHELL", "curl -f http://localhost:8080/healthcheck || exit 1"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      port_mappings = [
        {
          name          = "myapp"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      log_configuration = {
        logDriver = "awsfirelens"
        options   = {}
      }

      readonly_root_filesystem = false
      memory_reservation       = 1024 - 25
    }

    log_router = {
      cpu       = 25
      memory    = 25
      essential = true
      image     = "009160052643.dkr.ecr.ap-northeast-2.amazonaws.com/baseflue:latest"

      environment = [
        {
          name = "CONFIG",
          value = base64encode(<<-EOF
            [SERVICE]
              Flush           1
              Daemon          off
              Log_Level       debug
              Parsers_File    /parsers.conf

            # [FILTER]
            #   Name parser
            #   Match *
            #   Key_Name log
            #   Parser custom
            #   Reserve_Data On

            [OUTPUT]
              Name cloudwatch
              Match *
              region ap-northeast-2
              log_group_name /wsi/webapp/product
              log_stream_name $${TASK_ID}
              auto_create_group true
            EOF
          )
        },
        {
          name = "PARSERS",
          value = base64encode(<<-EOF
              [PARSER]
                Name custom
                Format regex
                Regex ^(?<remote_addr>.*) - - \[(?<time>.*)\] "(?<method>.*) (?<path>.*) (?<protocol>.*)" (?<status_code>.*) (?<latency>.*) "-" "(?<user_agent>.*)" "-"$
                Time_Key time
                Time_Format %d/%b/%Y:%H:%M:%S %z
                Time_Keep On
            EOF
          )
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-cluster/product-logroute"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }

      firelens_configuration = {
        type = "fluentbit"
        options = {
          config-file-type  = "file"
          config-file-value = "/config.conf"
        }
      }

      readonly_root_filesystem = false
      memory_reservation       = 25
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups.producttg1.arn
      container_name   = "product"
      container_port   = 8080
    }
  }

  # subnet_ids = module.vpc.private_subnets

  # V2
  subnet_ids = [for subnet in local.ecs_cluster_subnets : aws_subnet.this[subnet.key].id]

  security_group_rules = {
    alb_ingress_3000 = {
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

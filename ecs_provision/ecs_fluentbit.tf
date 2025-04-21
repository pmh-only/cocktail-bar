module "ecs_fluentbit" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  force_new_deployment = true
  force_delete         = true

  scheduling_strategy = "DAEMON"
  network_mode        = "host"

  name        = "fluentbit"
  cluster_arn = module.ecs.cluster_arn
  launch_type = "EC2"

  deployment_controller = {
    type = "ECS" # or CODE_DEPLOY
  }

  enable_execute_command   = true
  requires_compatibilities = ["EC2"]

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
    log_router = {
      essential = true
      image     = "009160052643.dkr.ecr.${var.region}.amazonaws.com/baseflue:latest"

      health_check = {
        command  = ["CMD-SHELL", "exit 0"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      environment = [
        {
          name = "CONFIG",
          value = base64encode(<<-EOF
            [SERVICE]
              Flush           1
              Daemon          off
              Log_Level       debug
              Parsers_File    /parsers.conf

            [INPUT]
              Name forward
              Unix_Path /var/run/fluent.sock

            [FILTER]
              Name ecs
              Match app.*
              ECS_Tag_Prefix app.
              ADD ecs_task_id $TaskID
              ADD ecs_task_family $TaskDefinitionFamily
              ADD ecs_task_arn $TaskARN
              ADD ecs_container_name $ECSContainerName
              ADD cluster $ClusterName

            [FILTER]
              Name          rewrite_tag
              Match         app.*
              Rule          ecs_task_family (.*) log.$1.$ecs_container_name false
              Emitter_Name  re_emitted

            # [FILTER]
            #   Name parser
            #   Match log.project-myapp.*
            #   Key_Name log
            #   Parser custom
            #   Preserve_Key True
            #   Reserve_Data True

            [OUTPUT]
              Name cloudwatch_logs
              Match log.*
              region ${var.region}
              log_group_template /aws/ecs/${local.ecs_cluster_name}/$ecs_task_family.$ecs_container_name
              log_group_name /aws/ecs/${local.ecs_cluster_name}/failback-logs
              log_stream_template $ecs_task_id
              log_stream_name failback
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
                Regex ^(?<remote_addr>.*) - - (?<time>.*) (?<method>.*) (?<path>.*) (?<status_code>.*) -$
                Time_Key time
                Time_Format %d/%m/%Y:%H:%M:%S
                Time_Keep True
            EOF
          )
        },
        {
          name = "PRE_EXEC",
          value = base64encode(<<-EOF
              ln -sf /config.conf /fluent-bit/etc/fluent-bit.conf
            EOF
          )
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/fluentbit"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }

      readonly_root_filesystem = false

      mount_points = [{
        containerPath = "/var/run"
        sourceVolume  = "socket"
      }]
    }
  }

  volume = {
    socket = {
      host_path = "/var/run"
    }
  }

  subnet_ids = [for subnet in local.ecs_cluster_subnets : aws_subnet.this[subnet.key].id]

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

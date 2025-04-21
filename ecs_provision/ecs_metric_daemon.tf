module "ecs_fluentbit" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  force_new_deployment = true
  force_delete         = true

  scheduling_strategy = "DAEMON"
  network_mode        = "host"

  name        = "metric-emitter"
  cluster_arn = module.ecs.cluster_arn
  launch_type = "EC2"

  deployment_controller = {
    type = "ECS" # or CODE_DEPLOY
  }

  enable_execute_command   = true
  requires_compatibilities = ["EC2"]

  tasks_iam_role_policies = {
    CloudWatchFullAccessV2 = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
    AmazonECS_FullAccess   = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
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
    metric-emitter = {
      essential = true
      image     = "ghcr.io/pmh-only/metric-emitter:ecs_daemon"

      health_check = {
        command  = ["CMD-SHELL", "exit 0"]
        interval = 5
        timeout  = 2
        retries  = 1
      }

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.ecs_cluster_name}/metric-emitter"
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

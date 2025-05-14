locals {
  ecs_cluster_name = "${var.project_name}-cluster"
}

resource "aws_ecs_account_setting_default" "containerInsights" {
  name  = "containerInsights"
  value = "enhanced"
}


resource "aws_ecs_account_setting_default" "awsvpcTrunking" {
  name  = "awsvpcTrunking"
  value = "enabled"
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name                = local.ecs_cluster_name
  create_cloudwatch_log_group = false

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enhanced"
    }
  ]

  # FARGATE
  # fargate_capacity_providers = {
  #   FARGATE = {
  #     default_capacity_provider_strategy = {
  #       weight = 20
  #     }
  #   }
  #   FARGATE_SPOT = {
  #     default_capacity_provider_strategy = {
  #       weight = 80
  #     }
  #   }
  # }

  # EC2
  autoscaling_capacity_providers = {
    EC2 = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "ENABLED"
      instance_warmup_period         = 0

      managed_scaling = {
        maximum_scaling_step_size = 32
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
    }
  }
}

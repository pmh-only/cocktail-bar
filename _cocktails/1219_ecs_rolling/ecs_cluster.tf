resource "aws_ecs_account_setting_default" "default" {
  name = "containerInsights"
  value = "enhanced"
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.project_name}-cluster"
  cloudwatch_log_group_name = "/aws/ecs/${var.project_name}-cluster"
  cluster_settings = [{
    name  = "containerInsights"
    value = "enhanced"
  }]

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 80
      }
    }
  }
  
  autoscaling_capacity_providers = {
    EC2 = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 32
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
    }
  }
}

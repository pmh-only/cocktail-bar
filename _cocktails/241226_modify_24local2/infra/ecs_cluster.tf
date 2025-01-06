resource "aws_ecs_account_setting_default" "default" {
  name = "containerInsights"
  value = "enhanced"
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.project_name}-ecs-cluster"
  cloudwatch_log_group_name = "/aws/ecs/${var.project_name}-ecs-cluster"
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
}

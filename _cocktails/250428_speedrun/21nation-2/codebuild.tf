locals {
  codebuild_projects = [
    "${var.project_name}-api-build",
    "${var.project_name}-api-release"
  ]
}

module "codebuild" {
  count = length(local.codebuild_projects)

  source = "cloudposse/codebuild/aws"
  name   = local.codebuild_projects[count.index]

  # build_image        = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
  build_image        = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
  build_compute_type = "BUILD_GENERAL1_SMALL"

  # build_type = "ARM_CONTAINER"
  build_type = "LINUX_CONTAINER"

  build_timeout = 60

  privileged_mode = true
  aws_region      = var.region
  image_repo_name = local.ecr_repositories[0]

  cache_type        = "LOCAL"
  local_cache_modes = ["LOCAL_SOURCE_CACHE", "LOCAL_DOCKER_LAYER_CACHE"]
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count = length(local.codebuild_projects)

  role       = module.codebuild[count.index].role_id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

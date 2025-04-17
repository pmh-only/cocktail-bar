locals {
  ecr_repositories = [
    "stress",
    "unicorn",
    "token",
    "location",
    "status"
  ]
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"
  count  = length(local.ecr_repositories)

  repository_name = local.ecr_repositories[count.index]

  repository_force_delete         = true
  repository_image_tag_mutability = "IMMUTABLE"
  repository_encryption_type      = "KMS"
  repository_image_scan_on_push   = true

  repository_read_write_access_arns = [
    data.aws_caller_identity.caller.arn
  ]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged image after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = 1
          countUnit   = "days"
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

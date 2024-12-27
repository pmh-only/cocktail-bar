locals {
  codecommit_repositories = [
    "${var.project_name}-backend-code",
    "${var.project_name}-frontend-code"
  ]
}

resource "aws_codecommit_repository" "repositories" {
  count = length(local.codecommit_repositories)
  repository_name = local.codecommit_repositories[count.index]
}

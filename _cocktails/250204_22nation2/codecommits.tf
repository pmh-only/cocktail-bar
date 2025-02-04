locals {
  codecommit_repositories = [
    "skills-commit",
  ]
}

resource "aws_codecommit_repository" "repositories" {
  count           = length(local.codecommit_repositories)
  repository_name = local.codecommit_repositories[count.index]
}

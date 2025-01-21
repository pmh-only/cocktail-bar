locals {
  codecommit_repositories = [
    "myapp",
  ]
}

resource "aws_codecommit_repository" "repositories" {
  count           = length(local.codecommit_repositories)
  repository_name = local.codecommit_repositories[count.index]
}

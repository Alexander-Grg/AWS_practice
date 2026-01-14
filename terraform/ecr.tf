locals {
  services = ["backend-flask", "frontend-react-js"]
}

resource "aws_ecr_repository" "app_repos" {
  for_each             = toset(local.services)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle Policy to delete old images (keeps only the last 10)
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  for_each   = aws_ecr_repository.app_repos
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output the repository URLs so you can use them in your push script
output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.app_repos : k => v.repository_url }
}
# ============================================================================
# ECR Repositories — Container Registries for Agent Images
# ============================================================================

resource "aws_ecr_repository" "orchestrator" {
  name                 = "${var.stack_name}-orchestrator"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name   = "${var.stack_name}-orchestrator-ecr"
    Module = "ECR"
    Agent  = "Orchestrator"
  }
}

resource "aws_ecr_repository" "research_analyst" {
  name                 = "${var.stack_name}-research-analyst"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name   = "${var.stack_name}-research-analyst-ecr"
    Module = "ECR"
    Agent  = "ResearchAnalyst"
  }
}

resource "aws_ecr_repository" "portfolio_advisor" {
  name                 = "${var.stack_name}-portfolio-advisor"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name   = "${var.stack_name}-portfolio-advisor-ecr"
    Module = "ECR"
    Agent  = "PortfolioAdvisor"
  }
}

# ECR Repository Policies
resource "aws_ecr_repository_policy" "orchestrator" {
  repository = aws_ecr_repository.orchestrator.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPullFromAccount"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.id}:root" }
      Action = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    }]
  })
}

resource "aws_ecr_repository_policy" "research_analyst" {
  repository = aws_ecr_repository.research_analyst.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPullFromAccount"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.id}:root" }
      Action = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    }]
  })
}

resource "aws_ecr_repository_policy" "portfolio_advisor" {
  repository = aws_ecr_repository.portfolio_advisor.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPullFromAccount"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.id}:root" }
      Action = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    }]
  })
}

# Lifecycle policies — keep last 5 images
resource "aws_ecr_lifecycle_policy" "orchestrator" {
  repository = aws_ecr_repository.orchestrator.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Keep last 5", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 }, action = { type = "expire" } }]
  })
}

resource "aws_ecr_lifecycle_policy" "research_analyst" {
  repository = aws_ecr_repository.research_analyst.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Keep last 5", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 }, action = { type = "expire" } }]
  })
}

resource "aws_ecr_lifecycle_policy" "portfolio_advisor" {
  repository = aws_ecr_repository.portfolio_advisor.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Keep last 5", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 }, action = { type = "expire" } }]
  })
}

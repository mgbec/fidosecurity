# ============================================================================
# CodeBuild Projects — Build ARM64 Docker Images for Each Agent
# ============================================================================

locals {
  agents = {
    orchestrator = {
      ecr_repo  = aws_ecr_repository.orchestrator
      s3_bucket = aws_s3_bucket.orchestrator_source
      s3_object = aws_s3_object.orchestrator_source
      buildspec = "buildspec.yml"
    }
    research_analyst = {
      ecr_repo  = aws_ecr_repository.research_analyst
      s3_bucket = aws_s3_bucket.research_analyst_source
      s3_object = aws_s3_object.research_analyst_source
      buildspec = "buildspec.yml"
    }
    portfolio_advisor = {
      ecr_repo  = aws_ecr_repository.portfolio_advisor
      s3_bucket = aws_s3_bucket.portfolio_advisor_source
      s3_object = aws_s3_object.portfolio_advisor_source
      buildspec = "buildspec.yml"
    }
  }
}

resource "aws_codebuild_project" "agent_build" {
  for_each = local.agents

  name          = "${var.stack_name}-${replace(each.key, "_", "-")}-build"
  description   = "Build ${each.key} agent Docker image"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 60

  artifacts { type = "NO_ARTIFACTS" }

  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.id }
    environment_variable { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.id }
    environment_variable { name = "IMAGE_REPO_NAME", value = each.value.ecr_repo.name }
    environment_variable { name = "IMAGE_TAG", value = var.image_tag }
  }

  source {
    type      = "S3"
    location  = "${each.value.s3_bucket.id}/${each.value.s3_object.key}"
    buildspec = file("${path.module}/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.stack_name}-${replace(each.key, "_", "-")}-build"
    }
  }

  tags = {
    Name   = "${var.stack_name}-${each.key}-build"
    Module = "CodeBuild"
    Agent  = each.key
  }

  depends_on = [aws_iam_role_policy.codebuild]
}

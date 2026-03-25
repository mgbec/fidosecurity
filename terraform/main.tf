# ============================================================================
# Build Orchestration — Sequential Agent Builds
# ============================================================================

resource "time_sleep" "wait_for_iam" {
  depends_on = [
    aws_iam_role_policy.codebuild,
    aws_iam_role_policy.orchestrator_execution,
    aws_iam_role_policy.research_analyst_execution,
    aws_iam_role_policy.portfolio_advisor_execution
  ]
  create_duration = "30s"
}

# Build script for triggering CodeBuild
resource "local_file" "build_script" {
  filename = "${path.module}/scripts/build-image.sh"
  content  = <<-EOF
    #!/bin/bash
    set -e
    PROJECT_NAME="$1"
    REGION="$2"
    REPO_NAME="$3"
    IMAGE_TAG="$4"
    REPO_URL="$5"

    echo "Starting build for $PROJECT_NAME..."
    BUILD_ID=$(aws codebuild start-build --project-name "$PROJECT_NAME" --region "$REGION" --query 'build.id' --output text)
    echo "Build started: $BUILD_ID"

    while true; do
      STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" --region "$REGION" --query 'builds[0].buildStatus' --output text)
      echo "Build status: $STATUS"
      if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Build succeeded!"
        break
      elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ] || [ "$STATUS" = "TIMED_OUT" ]; then
        echo "Build failed with status: $STATUS"
        exit 1
      fi
      sleep 15
    done
  EOF
  file_permission = "0755"
}

# --- Specialist agents build first (independent) ---

resource "null_resource" "build_research_analyst" {
  triggers = {
    build_project   = aws_codebuild_project.agent_build["research_analyst"].id
    source_code_md5 = data.archive_file.research_analyst_source.output_md5
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/build-image.sh \"${aws_codebuild_project.agent_build["research_analyst"].name}\" \"${data.aws_region.current.id}\" \"${aws_ecr_repository.research_analyst.name}\" \"${var.image_tag}\" \"${aws_ecr_repository.research_analyst.repository_url}\""
  }

  depends_on = [
    aws_codebuild_project.agent_build,
    aws_s3_object.research_analyst_source,
    local_file.build_script,
    time_sleep.wait_for_iam
  ]
}

resource "null_resource" "build_portfolio_advisor" {
  triggers = {
    build_project   = aws_codebuild_project.agent_build["portfolio_advisor"].id
    source_code_md5 = data.archive_file.portfolio_advisor_source.output_md5
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/build-image.sh \"${aws_codebuild_project.agent_build["portfolio_advisor"].name}\" \"${data.aws_region.current.id}\" \"${aws_ecr_repository.portfolio_advisor.name}\" \"${var.image_tag}\" \"${aws_ecr_repository.portfolio_advisor.repository_url}\""
  }

  depends_on = [
    aws_codebuild_project.agent_build,
    aws_s3_object.portfolio_advisor_source,
    local_file.build_script,
    time_sleep.wait_for_iam
  ]
}

# --- Orchestrator builds last (depends on specialists) ---

resource "null_resource" "build_orchestrator" {
  triggers = {
    build_project        = aws_codebuild_project.agent_build["orchestrator"].id
    source_code_md5      = data.archive_file.orchestrator_source.output_md5
    research_build       = null_resource.build_research_analyst.id
    portfolio_build      = null_resource.build_portfolio_advisor.id
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/build-image.sh \"${aws_codebuild_project.agent_build["orchestrator"].name}\" \"${data.aws_region.current.id}\" \"${aws_ecr_repository.orchestrator.name}\" \"${var.image_tag}\" \"${aws_ecr_repository.orchestrator.repository_url}\""
  }

  depends_on = [
    aws_codebuild_project.agent_build,
    aws_s3_object.orchestrator_source,
    null_resource.build_research_analyst,
    null_resource.build_portfolio_advisor,
    local_file.build_script,
    time_sleep.wait_for_iam
  ]
}

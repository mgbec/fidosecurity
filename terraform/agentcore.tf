# ============================================================================
# AgentCore Runtimes — Specialist Agents Deploy First
# ============================================================================

# --- Research Analyst (independent) ---
resource "aws_bedrockagentcore_agent_runtime" "research_analyst" {
  agent_runtime_name = "${replace(var.stack_name, "-", "_")}_ResearchAnalyst"
  description        = "Research analyst agent — market data analysis and financial research"
  role_arn           = aws_iam_role.research_analyst_execution.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.research_analyst.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = {
    AWS_REGION         = data.aws_region.current.id
    AWS_DEFAULT_REGION = data.aws_region.current.id
  }

  tags = {
    Name   = "${var.stack_name}-research-analyst-runtime"
    Module = "BedrockAgentCore"
    Agent  = "ResearchAnalyst"
  }

  depends_on = [
    null_resource.build_research_analyst,
    aws_iam_role_policy.research_analyst_execution,
    aws_iam_role_policy_attachment.research_analyst_managed
  ]
}

# --- Portfolio Advisor (independent) ---
resource "aws_bedrockagentcore_agent_runtime" "portfolio_advisor" {
  agent_runtime_name = "${replace(var.stack_name, "-", "_")}_PortfolioAdvisor"
  description        = "Portfolio advisor agent — allocation recommendations and risk assessment"
  role_arn           = aws_iam_role.portfolio_advisor_execution.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.portfolio_advisor.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = {
    AWS_REGION         = data.aws_region.current.id
    AWS_DEFAULT_REGION = data.aws_region.current.id
  }

  tags = {
    Name   = "${var.stack_name}-portfolio-advisor-runtime"
    Module = "BedrockAgentCore"
    Agent  = "PortfolioAdvisor"
  }

  depends_on = [
    null_resource.build_portfolio_advisor,
    aws_iam_role_policy.portfolio_advisor_execution,
    aws_iam_role_policy_attachment.portfolio_advisor_managed
  ]
}

# --- Orchestrator (depends on both specialists) ---
resource "aws_bedrockagentcore_agent_runtime" "orchestrator" {
  agent_runtime_name = "${replace(var.stack_name, "-", "_")}_Orchestrator"
  description        = "Orchestrator agent — routes user queries to specialist agents"
  role_arn           = aws_iam_role.orchestrator_execution.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.orchestrator.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = {
    AWS_REGION             = data.aws_region.current.id
    AWS_DEFAULT_REGION     = data.aws_region.current.id
    RESEARCH_ANALYST_ARN   = aws_bedrockagentcore_agent_runtime.research_analyst.agent_runtime_arn
    PORTFOLIO_ADVISOR_ARN  = aws_bedrockagentcore_agent_runtime.portfolio_advisor.agent_runtime_arn
    SESSIONS_TABLE         = aws_dynamodb_table.sessions.name
  }

  tags = {
    Name   = "${var.stack_name}-orchestrator-runtime"
    Module = "BedrockAgentCore"
    Agent  = "Orchestrator"
  }

  depends_on = [
    aws_bedrockagentcore_agent_runtime.research_analyst,
    aws_bedrockagentcore_agent_runtime.portfolio_advisor,
    null_resource.build_orchestrator,
    aws_iam_role_policy.orchestrator_execution,
    aws_iam_role_policy_attachment.orchestrator_managed
  ]
}

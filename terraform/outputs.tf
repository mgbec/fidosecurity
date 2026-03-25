# ============================================================================
# Public Endpoints
# ============================================================================

output "api_endpoint" {
  description = "Public API endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.app.id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}

# ============================================================================
# Agent Runtimes
# ============================================================================

output "orchestrator_runtime_arn" {
  description = "Orchestrator agent runtime ARN"
  value       = aws_bedrockagentcore_agent_runtime.orchestrator.agent_runtime_arn
}

output "research_analyst_runtime_arn" {
  description = "Research analyst agent runtime ARN"
  value       = aws_bedrockagentcore_agent_runtime.research_analyst.agent_runtime_arn
}

output "portfolio_advisor_runtime_arn" {
  description = "Portfolio advisor agent runtime ARN"
  value       = aws_bedrockagentcore_agent_runtime.portfolio_advisor.agent_runtime_arn
}

# ============================================================================
# Testing
# ============================================================================

output "test_command" {
  description = "Quick test command (requires valid JWT)"
  value       = "curl -X POST ${aws_apigatewayv2_api.main.api_endpoint}/advisor -H 'Authorization: Bearer <JWT>' -H 'Content-Type: application/json' -d '{\"prompt\": \"Analyze my portfolio: 60% stocks, 30% bonds, 10% cash. I am 35 years old with moderate risk tolerance.\"}'"
}

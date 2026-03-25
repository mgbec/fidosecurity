# ============================================================================
# Lambda — API Request Handler (bridges API Gateway → AgentCore)
# ============================================================================

data "archive_file" "lambda_handler" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.terraform/lambda-handler.zip"
}

resource "aws_lambda_function" "api_handler" {
  function_name    = "${var.stack_name}-api-handler"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256
  filename         = data.archive_file.lambda_handler.output_path
  source_code_hash = data.archive_file.lambda_handler.output_base64sha256

  environment {
    variables = {
      ORCHESTRATOR_ARN = aws_bedrockagentcore_agent_runtime.orchestrator.agent_runtime_arn
      SESSIONS_TABLE   = aws_dynamodb_table.sessions.name
      AWS_REGION_NAME  = var.aws_region
    }
  }

  tags = {
    Name   = "${var.stack_name}-api-handler"
    Module = "Lambda"
  }

  depends_on = [
    aws_iam_role_policy.lambda_execution,
    aws_cloudwatch_log_group.lambda
  ]
}

# ============================================================================
# Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_execution" {
  name = "${var.stack_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name   = "${var.stack_name}-lambda-execution-role"
    Module = "IAM"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_execution" {
  name = "LambdaExecutionPolicy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeOrchestrator"
        Effect = "Allow"
        Action = ["bedrock-agentcore:InvokeAgentRuntime"]
        Resource = [
          "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.id}:runtime/*"
        ]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.sessions.arn,
          "${aws_dynamodb_table.sessions.arn}/index/*"
        ]
      }
    ]
  })
}

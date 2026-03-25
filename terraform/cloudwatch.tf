# ============================================================================
# CloudWatch — Logging & Monitoring
# ============================================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.stack_name}"
  retention_in_days = 30
  tags              = { Name = "${var.stack_name}-api-logs", Module = "CloudWatch" }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.stack_name}-api-handler"
  retention_in_days = 30
  tags              = { Name = "${var.stack_name}-lambda-logs", Module = "CloudWatch" }
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.stack_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda function error rate exceeded threshold"

  dimensions = {
    FunctionName = aws_lambda_function.api_handler.function_name
  }

  tags = { Name = "${var.stack_name}-lambda-errors-alarm", Module = "CloudWatch" }
}

# Environment detection in locals
locals {
  post_confirmation_handler = "post_confirmation.lambda_handler"
  messaging_stream_handler  = "messaging_stream.lambda_handler"
  db_connection_string = "postgresql://${aws_db_instance.webapp_rds_instance.username}:${aws_db_instance.webapp_rds_instance.password}@${aws_db_instance.webapp_rds_instance.endpoint}/${aws_db_instance.webapp_rds_instance.db_name}"
}

# CloudWatch Log Group for Post Confirmation Lambda
resource "aws_cloudwatch_log_group" "lambda_post_confirmation_logs" {
  name              = "/aws/lambda/${var.function_name_lambda_post_confirmation}"
  retention_in_days = 14

  tags = {
    Name        = "${var.function_name_lambda_post_confirmation}-logs"
    Environment = var.environment
  }
}

# Post Confirmation Lambda Function
resource "aws_lambda_function" "webapp_post_confirmation" {
  filename         = data.archive_file.lambda_post_confirmation_lambda_zip.output_path
  function_name    = var.function_name_lambda_post_confirmation
  role             = aws_iam_role.webapp_post_confirmation_role.arn
  handler          = local.post_confirmation_handler
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  architectures    = ["x86_64"]
  package_type     = "Zip"

  environment {
    variables = {
      PROD_CONNECTION_STRING = local.db_connection_string
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.subnet_2a.id != null ? [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id] : []
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda_post_confirmation_logs.name
  }

  tags = {
    Name        = var.function_name_lambda_post_confirmation
    Environment = var.environment
    # Removed EnvironmentType tag
  }
}

# Lambda Permission for Cognito to invoke Post Confirmation Lambda
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webapp_post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn = aws_cognito_user_pool.main.arn
}

# CloudWatch Log Group for Messaging Stream Lambda
resource "aws_cloudwatch_log_group" "webapp_messaging_stream_logs" {
  name              = "/aws/lambda/${var.function_name_webapp_messaging_stream}"
  retention_in_days = 14

  tags = {
    Name        = "${var.function_name_webapp_messaging_stream}-logs"
    Environment = var.environment
  }
}

# Messaging Stream Lambda Function
resource "aws_lambda_function" "webapp_messaging_stream" {
  filename         = data.archive_file.webapp_messaging_stream_lambda_zip.output_path
  function_name    = var.function_name_webapp_messaging_stream
  role             = aws_iam_role.messaging_stream_lambda_role.arn
  handler          = local.messaging_stream_handler
  runtime          = "python3.12"
  timeout          = 3
  memory_size      = 128
  architectures    = ["x86_64"]
  package_type     = "Zip"

  vpc_config {
    subnet_ids         = aws_subnet.subnet_2a.id != null ? [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id] : []
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.webapp_messaging_stream_logs.name
  }

  tags = {
    Name        = var.function_name_webapp_messaging_stream
    Environment = var.environment
    # Removed EnvironmentType tag
  }
}

# Event Source Mapping for DynamoDB Stream to Messaging Stream Lambda
resource "aws_lambda_event_source_mapping" "messaging_stream_trigger" {
  event_source_arn  = aws_dynamodb_table.webapp_messages.stream_arn
  function_name     = aws_lambda_function.webapp_messaging_stream.arn
  starting_position = "LATEST"
  batch_size        = 1
  enabled           = true
}

# Post Confirmation Lambda Outputs
output "webapp_post_confirmation_lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.webapp_post_confirmation.arn
}

output "post_confirmation_lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.webapp_post_confirmation.function_name
}

output "post_confirmation_lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.webapp_post_confirmation_role.arn
}

output "lpost_confirmation_lambda_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_post_confirmation_logs.name
}

# Messaging Stream Lambda Outputs
output "webapp_messaging_stream_lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.webapp_messaging_stream.arn
}

output "messaging_stream_lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.webapp_messaging_stream.function_name
}

output "messaging_stream_lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.messaging_stream_lambda_role.arn
}

output "messaging_stream_lambda_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.webapp_messaging_stream_logs.name
}
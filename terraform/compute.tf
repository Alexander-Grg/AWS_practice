# Environment detection in locals
locals {
  is_codespaces = var.is_codespaces
  
  # File names and handlers for each environment
  post_confirmation_filename = local.is_codespaces ? "post_confirmation.py" : "lambda_function.py"
  messaging_stream_filename = local.is_codespaces ? "messaging_stream.py" : "lambda_function.py"
  
  post_confirmation_handler = local.is_codespaces ? "post_confirmation.lambda_handler" : "lambda_function.lambda_handler"
  messaging_stream_handler = local.is_codespaces ? "messaging_stream.lambda_handler" : "lambda_function.lambda_handler"
  
  # Connection string based on environment
  db_connection_string = "postgresql://${aws_db_instance.webapp_rds_instance.username}:${aws_db_instance.webapp_rds_instance.password}@${aws_db_instance.webapp_rds_instance.endpoint}/${aws_db_instance.webapp_rds_instance.db_name}"
}

# Create Lambda function source code
resource "local_file" "lambda_post_confirmation_source" {
  filename = "${path.module}/${local.post_confirmation_filename}"
  content  = <<EOF
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      print('entered-try')
      sql = """
          INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(%s,%s,%s,%s)
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('PROD_CONNECTION_STRING'))
      cur = conn.cursor()
      params = [
        user_display_name,
        user_email,
        user_handle,
        user_cognito_id
      ]
      cur.execute(sql, params)
      conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
EOF
}

# Archive for Post Confirmation Lambda
data "archive_file" "lambda_post_confirmation_lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_post_confirmation_source.filename
  output_path = "${path.module}/post_confirmation.zip"
}

# Create Messaging Stream Lambda source code
resource "local_file" "webapp_messaging_stream_source" {
  filename = "${path.module}/${local.messaging_stream_filename}"
  content  = <<EOF
import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource('dynamodb')
table_name = 'webapp-messages'
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print('event:', event)
    
    message_group_uuid = event['message_group_uuid']
    
    # Query DynamoDB
    response = table.query(
        KeyConditionExpression=Key('message_group_uuid').eq(message_group_uuid)
    )
    return {
        'statusCode': 200,
        'body': json.dumps(response['Items'])
    }
EOF
}

# Archive for Messaging Stream Lambda
data "archive_file" "webapp_messaging_stream_lambda_zip" {
  type        = "zip"
  source_file = local_file.webapp_messaging_stream_source.filename
  output_path = "${path.module}/messaging_stream.zip"
}

# Conditional psycopg2 layer building - only in Codespaces
resource "null_resource" "build_psycopg2_layer" {
  count = local.is_codespaces ? 1 : 0

  triggers = {
    requirements = filemd5("${path.module}/layers/psycopg2/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/layers/psycopg2/python
      mkdir -p ${path.module}/layers/psycopg2/python
      pip install -r ${path.module}/layers/psycopg2/requirements.txt \
        -t ${path.module}/layers/psycopg2/python \
        --platform manylinux2014_x86_64 \
        --only-binary=:all: \
        --implementation cp \
        --python-version 3.12
    EOT
  }
}

# Archive for psycopg2 layer - УПРОЩЕННАЯ ВЕРСИЯ БЕЗ depends_on
data "archive_file" "psycopg2_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layers/psycopg2"
  output_path = "${path.module}/layers/psycopg2.zip"
  excludes    = ["requirements.txt"]
}

# Lambda Layer for psycopg2
resource "aws_lambda_layer_version" "psycopg2" {
  filename               = data.archive_file.psycopg2_layer_zip.output_path
  layer_name             = "psycopg2-python312-layer"
  description            = "Psycopg2 binary for Python 3.12 ${local.is_codespaces ? "(Built for Codespaces)" : "(Built locally)"}"
  source_code_hash       = data.archive_file.psycopg2_layer_zip.output_base64sha256
  compatible_runtimes    = ["python3.12"]
  compatible_architectures = ["x86_64"]
}

# IAM Policy Attachment for Post Confirmation Lambda
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
  role       = aws_iam_role.webapp_post_confirmation_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
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
  layers           = [aws_lambda_layer_version.psycopg2.arn]

  environment {
    variables = {
      PROD_CONNECTION_STRING = local.db_connection_string
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.subnet_2a.id != null ? [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id] : []
    security_group_ids = [aws_security_group.ssh_only.id]
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
    EnvironmentType = local.is_codespaces ? "codespaces" : "local"
  }
}

# Lambda Permission for Cognito to invoke Post Confirmation Lambda
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webapp_post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
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
    security_group_ids = [aws_security_group.ssh_only.id]
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
    EnvironmentType = local.is_codespaces ? "codespaces" : "local"
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
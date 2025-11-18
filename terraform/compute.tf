# Create Lambda function source code
resource "local_file" "lambda_post_confirmation_source" {
  content  = <<EOF
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email        = user['email']
    user_handle       = user['preferred_username']
    user_cognito_id   = user['sub']
    try:
      print('entered-try')
      sql = f"""
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
      cur.execute(sql,params)
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
  filename = "${path.module}/lambda_function.py"
}

# Attach EC2 policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
  role       = aws_iam_role.post_confirmation_lambda_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_post_confirmation_logs" {
  name              = "/aws/lambda/${var.function_name_lambda_post_confirmation}"
  retention_in_days = 14

  tags = {
    Name        = "${var.function_name_lambda_post_confirmation}-logs"
    Environment = var.environment
  }
}

# Lambda function
resource "aws_lambda_function" "webapp_post_confirmation" {
  filename      = data.archive_file.lambda_post_confirmation_lambda_zip.output_path
  function_name = var.function_name_lambda_post_confirmation
  role          = aws_iam_role.webapp_post_confirmation_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 3
  memory_size   = 128
  architectures = ["x86_64"]
  package_type  = "Zip"
  layers        = [var.psycopg2_layer_arn]

  vpc_config {
    subnet_ids         = aws_subnet.subnet_2a.id != null ? [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id] : []
    security_group_ids = [aws_security_group.default_sg.vpc_id]
  }

  environment {
    variables = {
      PROD_CONNECTION_STRING = var.prod_connection_string
    }
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

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy_attachment.lambda_ec2_policy_attachment,
    aws_cloudwatch_log_group.lambda_post_confirmation_logs,
    data.archive_file.lambda_post_confirmation_lambda_zip
  ]

  tags = {
    Name        = var.function_name_lambda_post_confirmation
    Environment = var.environment
  }
}

# Lambda permission for Cognito to invoke the function
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webapp_post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
}

# Outputs
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

# Create Lambda function source code
resource "local_file" "webapp_messaging_stream_source" {
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
    
    # Return the items
    return {
        'statusCode': 200,
        'body': json.dumps(response['Items'])
    }
EOF
  filename = "${path.module}/lambda_function.py"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "webapp_messaging_stream_logs" {
  name              = "/aws/lambda/${var.function_name_webapp_messaging_stream}"
  retention_in_days = 14

  tags = {
    Name        = "${var.function_name_webapp_messaging_stream}-logs"
    Environment = var.environment
  }
}

# Lambda function
resource "aws_lambda_function" "webapp_messaging_stream" {
  filename      = data.archive_file.webapp_messaging_stream_lambda_zip.output_path
  function_name = var.function_name_webapp_messaging_stream
  role          = aws_iam_role.messaging_stream_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 3
  memory_size   = 128
  architectures = ["x86_64"]
  package_type  = "Zip"

  vpc_config {
    subnet_ids         = aws_subnet.subnet_2a.id != null ? [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id] : []
    security_group_ids = [aws_security_group.default_sg.vpc_id]
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

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy_attachment.lambda_dynamodb_policy_attachment,
    aws_cloudwatch_log_group.webapp_messaging_stream_logs,
    data.archive_file.webapp_messaging_stream_lambda_zip
  ]

  tags = {
    Name        = var.function_name_webapp_messaging_stream
    Environment = var.environment
  }
}

# Outputs
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

# Lambda Layer for psycopg2
resource "aws_lambda_layer_version" "psycopg2_layer" {
  filename         = "psycopg2-layer.zip"
  layer_name       = "psycopg2"
  description      = "psycopg2 layer for PostgreSQL connectivity"
  
  compatible_runtimes = ["python3.9"]
}

# IAM Role for webapp-post-confirmation2
resource "aws_iam_role" "webapp_post_confirmation2_role" {
  name = "webapp-post-confirmation2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


# IAM Policy for VPC access
resource "aws_iam_role_policy_attachment" "webapp_post_confirmation2_vpc_policy" {
  role       = aws_iam_role.webapp_post_confirmation2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Function - webapp-post-confirmation2
resource "aws_lambda_function" "webapp_post_confirmation2" {
  filename         = "webapp-post-confirmation2.zip"  # You'll need to create this zip file
  function_name    = "webapp-post-confirmation2"
  role            = aws_iam_role.webapp_post_confirmation2_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  
  # Configuration
  memory_size = 128
  timeout     = 3
  
  # Architecture
  architectures = ["x86_64"]
  package_type  = "Zip"
  
  # VPC Configuration
  vpc_config {
    subnet_ids         = ["subnet-05fdd389fd107a155", "subnet-08e97c52ff755ea6b", "subnet-0e7147a4b6fa0207d"]
    security_group_ids = ["sg-0c6ff8e93bd998253"]
  }
  
  # Environment Variables
  environment {
    variables = {
      PROD_CONNECTION_STRING = data.dotenv.backend.env["PROD_CONNECTION_STRING"]
    }
  }
  
  # Layer
  layers = [aws_lambda_layer_version.psycopg2_layer.arn]
  
  tags = {
    Name        = "webapp-post-confirmation2"
    Environment = "production"
  }
}

# Updated DynamoDB Stream Event Source Mapping
resource "aws_lambda_event_source_mapping" "webapp_messaging_stream_trigger" {
  event_source_arn  = aws_dynamodb_table.webapp_messages.stream_arn
  function_name     = aws_lambda_function.webapp_messaging_stream.arn
  starting_position = "LATEST"
  batch_size        = 1
  enabled           = true

  depends_on = [
    aws_dynamodb_table.webapp_messages,
    aws_lambda_function.webapp_messaging_stream
  ]
}


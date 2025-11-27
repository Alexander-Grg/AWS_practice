# Security Group 1: launch-wizard-1
resource "aws_security_group" "launch_wizard_1" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2025-08-04T06:06:16.489Z"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "launch-wizard-1"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Security Group 2: default
resource "aws_security_group" "default_sg" {
  name        = "webapp-main-sg"
  description = "default VPC security group"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  ingress {
    description = "PostgreSQL access for the localhost"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  ingress {
    description     = "PostgreSQL access for Fargate backend service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.post_srv_sg.id]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # ingress {
  #   description = "ICMPv6 access"
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmpv6"
  #   cidr_blocks = [var.icmpv6_ip]
  # }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "default"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Security Group 3: post-srv-sg
resource "aws_security_group" "post_srv_sg" {
  name        = "post-srv-sg"
  description = "Security group for Webapp services on ECS"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "post-srv-sg"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_self_reference" {
  description              = "Allow resources in this SG to talk to each other (Lambda to RDS)"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1" # Or "tcp" if you want to be specific
  security_group_id        = aws_security_group.default_sg.id
  source_security_group_id = aws_security_group.default_sg.id
}

# Outputs for reference
output "launch_wizard_1_sg_id" {
  description = "ID of the launch-wizard-1 security group"
  value       = aws_security_group.launch_wizard_1.id
}

output "default_sg_id" {
  description = "ID of the default security group"
  value       = aws_security_group.default_sg.id
}

output "post_srv_sg_id" {
  description = "ID of the post-srv-sg security group"
  value       = aws_security_group.post_srv_sg.id
}

# IAM Role for webapp-post-confirmation Lambda Function
resource "aws_iam_role" "webapp_post_confirmation_role" {
  name = "webapp-post-confirmation-role"

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
resource "aws_iam_role_policy_attachment" "webapp_post_confirmation_vpc_policy" {
  role       = aws_iam_role.webapp_post_confirmation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM Policy for EC2 network interface operations
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "${var.function_name_webapp_messaging_stream}-ec2-policy"
  description = "Policy for Lambda to manage EC2 network interfaces"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Lambda function
resource "aws_iam_role" "messaging_stream_lambda_role" {
  name = "${var.function_name_webapp_messaging_stream}-role"

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

  tags = {
    Name        = "${var.function_name_webapp_messaging_stream}-role"
    Environment = var.environment
  }
}

# IAM Role for Lambda function
resource "aws_iam_role" "post_confirmation_lambda_role" {
  name = "${var.function_name_lambda_post_confirmation}-role"

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

  tags = {
    Name        = "${var.function_name_lambda_post_confirmation}-role"
    Environment = var.environment
  }
}

# IAM Policy for DynamoDB access
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.function_name_webapp_messaging_stream}-dynamodb-policy"
  description = "Policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.dotenv.main.env["AWS_DEFAULT_REGION"]}:${data.dotenv.main.env["AWS_ACCOUNT_ID"]}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${data.dotenv.main.env["AWS_DEFAULT_REGION"]}:${data.dotenv.main.env["AWS_ACCOUNT_ID"]}:table/${var.dynamodb_table_name}/stream/*"
        ]
      }
    ]
  })
}

# Attach DynamoDB policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach AWS managed policy for VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# 1. The User Pool
resource "aws_cognito_user_pool" "main" {
  name = "webapp-user-pool"

  # Allow users to sign in with their email address
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Account Confirmation"
    email_message = "Your confirmation code is {####}"
  }

  schema {
    attribute_data_type = "String"
    name               = "name"
    required           = true
    mutable           = true
  }

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }
  
  lambda_config {
    post_confirmation = aws_lambda_function.webapp_post_confirmation.arn
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "webapp-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false
  
  # CRITICAL for Amplify/Web SDKs
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]

  # OAuth Settings
  supported_identity_providers = ["COGNITO"]
  callback_urls = ["http://localhost:3000/signin"]
  logout_urls   = ["http://localhost:3000/signin"]
}

# 3. Identity Pool (For swapping JWT tokens for AWS Credentials)
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "webapp-identity-pool"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }
}

resource "aws_iam_role" "authenticated" {
  name = "webapp-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "StringEquals" = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# Basic policy for authenticated users
resource "aws_iam_role_policy" "authenticated_policy" {
  name = "webapp-authenticated-policy"
  role = aws_iam_role.authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.authenticated.arn
  }
}

output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.client.id
}
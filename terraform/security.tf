# SECURITY GROUPS
resource "aws_security_group" "ssh_only" {
  name        = "no-ingress-sg"
  description = "No Inbound Access - Managed via SSM"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "no-ingress-sg"
  }
}

resource "aws_security_group" "post_srv_sg" {
  name        = "post-srv-sg"
  description = "Security group for Webapp services on ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

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
  description              = "SG for internal resources intercommunication"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.ssh_only.id
  source_security_group_id = aws_security_group.ssh_only.id
}

# IAM Role for the Session Manager (EC2 access)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# LAMBDA & COGNITO IAM

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

resource "aws_iam_role_policy_attachment" "webapp_post_confirmation_vpc_policy" {
  role       = aws_iam_role.webapp_post_confirmation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

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
          "arn:aws:dynamodb:${var.default_region}:${var.aws_account_id}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${var.default_region}:${var.aws_account_id}:table/${var.dynamodb_table_name}/stream/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.messaging_stream_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# COGNITO
resource "aws_cognito_user_pool" "main" {
  name = "webapp-user-pool"

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
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
  
  callback_urls = ["http://localhost:3000/signin"]
  logout_urls   = ["http://localhost:3000/signin"]
}

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
        Principal = { Federated = "cognito-identity.amazonaws.com" }
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

# OUTPUTS
output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "default_sg_id" {
  description = "ID of the default security group"
  value       = aws_security_group.ssh_only.id
}

output "post_srv_sg_id" {
  description = "ID of the post-srv-sg security group"
  value       = aws_security_group.post_srv_sg.id
}

output "ssm_instance_profile_name" {
  description = "Name of the IAM instance profile for SSM"
  value       = aws_iam_instance_profile.ec2_ssm_profile.name
}

# LAMBDA SECURITY GROUP (For RDS Access)
resource "aws_security_group" "lambda_sg" {
  name        = "webapp-lambda-sg"
  description = "Security Group for Lambda to access RDS"
  vpc_id      = aws_vpc.main.id 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  
  security_group_id        = aws_security_group.ssh_only.id
  source_security_group_id = aws_security_group.lambda_sg.id
}
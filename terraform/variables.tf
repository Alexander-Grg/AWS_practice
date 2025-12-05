variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cruddur"
}

variable "db_password" {
  description = "Variable for PG db"
  type = string
  sensitive = true
}

variable "allowed_ip" {
  description = "IP that allowed for the AWS security group"
  type = string
  sensitive = true
}

variable "aws_account_id" {
  description = "AWS account ID"
  type = string
  sensitive = true
}

variable "default_region" {
  description = "AWS default region"
  type = string
}

variable "ip_range" {
  description = "A range of codespaces ips"
  type = string
  sensitive = true
}

# Lambda function post-confirmation
variable "function_name_lambda_post_confirmation" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cruddur-post-confirmation2"
}

# variable "prod_connection_string" {
#   description = "PostgreSQL connection string for production database"
#   type        = string
#   sensitive   = true
# }

variable "psycopg2_layer_arn" {
  description = "ARN of the psycopg2 Lambda layer"
  type        = string
  default     = "arn:aws:lambda:ap-southeast-2:990588950671:layer:psycopg2:2"
}

# Lambda function cruddur_messaging_stream
variable "function_name_cruddur_messaging_stream" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cruddur-messaging-stream"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "cruddur-messages"
}

# Enviroment variable
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# CloudWatch

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "alx.a.grg@gmail.com"
}
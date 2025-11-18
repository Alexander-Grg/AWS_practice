# Lambda function post-confirmation
variable "function_name_lambda_post_confirmation" {
  description = "Name of the Lambda function"
  type        = string
  default     = "webapp-post-confirmation2"
}

variable "prod_connection_string" {
  description = "PostgreSQL connection string for production database"
  type        = string
  sensitive   = true
}

variable "psycopg2_layer_arn" {
  description = "ARN of the psycopg2 Lambda layer"
  type        = string
  default     = "arn:aws:lambda:ap-southeast-2:990588950671:layer:psycopg2:2"
}

# Lambda function webapp_messaging_stream
variable "function_name_webapp_messaging_stream" {
  description = "Name of the Lambda function"
  type        = string
  default     = "webapp-messaging-stream"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "webapp-messages"
}

# Enviroment variable
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
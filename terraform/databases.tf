# RDS Database Instance - webapp-rds-instance
# tfsec:ignore:aws-rds-enable-iam-authentication
resource "aws_db_instance" "webapp_rds_instance" {
  identifier     = "webapp-rds-instance"
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = "db.t3.micro"

  db_name  = "webapp"
  username = "root"
  password = var.db_password
  port     = 5432

  # iam_database_authentication_enabled = true

  allocated_storage = 20
  storage_type      = "gp3" 
  storage_encrypted = true
  publicly_accessible  = false

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.webapp_db_subnet_group.name
  
  backup_retention_period = 7
    # For production env should be false
  skip_final_snapshot     = true
    # For production env should be true
  deletion_protection     = false 

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = aws_kms_key.rds_pi_key.arn

  # Essential for Postgres health
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name        = "webapp-rds-instance"
    Environment = "production"
  }
}

# Output the database endpoint
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.webapp_rds_instance.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.webapp_rds_instance.port
}

output "db_connection_string" {
  description = "Connection string for local development"
  value       = "postgresql://root:${var.db_password}@${aws_db_instance.webapp_rds_instance.endpoint}/webapp"
  sensitive   = true
}

# Dynamo DB table

resource "aws_dynamodb_table" "webapp_messages" {
  name           = "webapp-messages"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "pk"
  range_key      = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "message_group_uuid"
    type = "S"
  }

  global_secondary_index {
    name            = "message-group-sk-index"
    hash_key        = "message_group_uuid"
    range_key       = "sk"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  server_side_encryption {
    enabled = true 
  }

  # deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "webapp-messages"
    Environment = "production"
    Application = "webapp"
  }
}

# Output the table details
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.webapp_messages.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.webapp_messages.arn
}

output "dynamodb_table_stream_arn" {
  description = "ARN of the DynamoDB table stream"
  value       = aws_dynamodb_table.webapp_messages.stream_arn
}

output "dynamodb_table_stream_label" {
  description = "Stream label of the DynamoDB table"
  value       = aws_dynamodb_table.webapp_messages.stream_label
}

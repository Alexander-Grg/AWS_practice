# RDS Database Instance - webapp-rds-instance
resource "aws_db_instance" "webapp_rds_instance" {
  # Basic Configuration
  identifier     = "webapp-rds-instance"
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = "db.t3.micro"

  # Database Configuration
  db_name  = "webapp"
  username = "root"
  password = var.db_password
  port     = 5432

  # Storage Configuration
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  # Network & Security
  vpc_security_group_ids = [aws_security_group.ssh_only.id]
  db_subnet_group_name   = aws_db_subnet_group.webapp_db_subnet_group.name
  availability_zone      = "ap-southeast-2a"
  publicly_accessible    = true
  network_type           = "IPV4"

  # Backup Configuration
  backup_retention_period = 0
  backup_window           = "16:55-17:25"
  backup_target           = "region"
  copy_tags_to_snapshot   = false

  # Maintenance Configuration
  maintenance_window         = "Sun:14:15-Sun:14:45"
  auto_minor_version_upgrade = true
  deletion_protection        = false

  # Parameter and Option Groups
  parameter_group_name = "default.postgres17"
  option_group_name    = "default:postgres-17"

  # Monitoring & Performance
  monitoring_interval                   = 0
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Additional Configuration
  multi_az           = false
  license_model      = "postgresql-license"
  ca_cert_identifier = "rds-ca-rsa2048-g1"

  # Authentication
  iam_database_authentication_enabled = false

  skip_final_snapshot = true

  tags = {
    Name        = "webapp-rds-instance"
    Environment = "development"
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


# DynamoDB Table - webapp-messages
resource "aws_dynamodb_table" "webapp_messages" {
  name           = "webapp-messages"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "pk"
  range_key      = "sk"

  # Attribute Definitions
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

  # Global Secondary Index
  global_secondary_index {
    name            = "message-group-sk-index"
    hash_key        = "message_group_uuid"
    range_key       = "sk"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  # Stream Configuration
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  # Additional Settings
  deletion_protection_enabled = false

  # Point-in-time recovery (currently disabled)
  point_in_time_recovery {
    enabled = false
  }

  # Server-side encryption (currently disabled)
  server_side_encryption {
    enabled = false
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

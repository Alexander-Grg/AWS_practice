resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "${var.project_name}-cloudwatch-alerts"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_log_group" "webapp_fargate_cluster_managed" {
  name              = "/webapp/fargate-cluster"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

# RDS CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapp_rds_instance.identifier
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connection_count" {
  alarm_name          = "${var.project_name}-rds-connection-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapp_rds_instance.identifier
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  alarm_name          = "${var.project_name}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000000000" # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapp_rds_instance.identifier
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# DynamoDB CloudWatch Alarms (based on your webapp-messages table)
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttled_events" {
  alarm_name          = "${var.project_name}-dynamodb-read-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttling"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.webapp_messages.name
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttled_events" {
  alarm_name          = "${var.project_name}-dynamodb-write-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB write throttling"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.webapp_messages.name
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Billing Alarms
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.south
  alarm_name          = "${var.project_name}-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This metric monitors estimated charges"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "${var.project_name}-main-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.webapp_rds_instance.identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-southeast-1"
          title   = "RDS Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.webapp_messages.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ProvisionedReadCapacityUnits", ".", "."],
            [".", "ProvisionedWriteCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-southeast-1"
          title   = "DynamoDB Metrics"
          period  = 300
        }
      }
    ]
  })
}

# Custom Metric Filter (example for application logs)
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.webapp_fargate_cluster_managed.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/Application"
    value     = "1"
  }
}

# Alarm for custom metric
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  alarm_name          = "${var.project_name}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors application errors"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Provider configuration for multi-region resources
provider "aws" {
  alias  = "south"
  region = "ap-southeast-2"
}

# Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alerts"
  value       = aws_sns_topic.cloudwatch_alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main_dashboard.dashboard_name}"
}

data "aws_region" "current" {}

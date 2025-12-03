provider "aws" {
  region = "ap-southeast-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# Create ZIP file for Lambda deployment
data "archive_file" "lambda_post_confirmation_lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_post_confirmation_source.filename
  output_path = "${path.module}/post_confirmation.zip"
}

data "archive_file" "webapp_messaging_stream_lambda_zip" {
  type        = "zip"
  source_file = local_file.webapp_messaging_stream_source.filename
  output_path = "${path.module}/messaging_stream.zip"
}
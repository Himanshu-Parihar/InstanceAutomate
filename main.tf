provider "aws" {
  region = "ap-south-1"
}
# Assuming Access creds are already saved on the server hosting this script

# Policy for Lambda execution role
resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_execution_policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:StartInstances",
	  "ec2:StopInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

# Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [aws_iam_policy.lambda_policy.arn]
}

# Lambda to start instances
resource "aws_lambda_function" "start_ec2_instances" {
  filename      = "start_ec2.zip"
  function_name = "start_ec2_instances"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  environment {
    variables = {
      tag_key   = var.ec2_tag_key
      tag_value = var.ec2_tag_value
    }
  }
}

# Lambda to stop instances
resource "aws_lambda_function" "stop_ec2_instances" {
  filename      = "stop_ec2.zip"
  function_name = "stop_ec2_instances"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  environment {
    variables = {
      tag_key   = var.ec2_tag_key
      tag_value = var.ec2_tag_value
    }
  }
}

# Events Rule for starting EC2 instances
resource "aws_cloudwatch_event_rule" "start_ec2_schedule_rule" {
  name                = "start_ec2_schedule_rule"
  schedule_expression = var.start_schedule_expression
}

# Events Target to trigger Lambda for starting EC2 instances
resource "aws_cloudwatch_event_target" "start_ec2_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_schedule_rule.name
  target_id = "start_ec2_target"
  arn       = aws_lambda_function.start_ec2_instances.arn
}

# Events Rule for stopping EC2 instances
resource "aws_cloudwatch_event_rule" "stop_ec2_schedule_rule" {
  name                = "stop_ec2_schedule_rule"
  schedule_expression = var.stop_schedule_expression
}

# Events Target to trigger Lambda for stopping EC2 instances
resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_schedule_rule.name
  target_id = "stop_ec2_target"
  arn       = aws_lambda_function.stop_ec2_instances.arn
}
# Variables can be passed in seperate varibale.tf file but here passing in same file.
# Variable for schedule expression for starting EC2 instances (default: Start at 08:00 on weekdays)
variable "start_schedule_expression" {
  default = "cron(0 8 * * MON-FRI)"
}

# Variable for schedule expression for stopping EC2 instances (default: Stop at 17:00 on weekdays)
variable "stop_schedule_expression" {
  default = "cron(0 17 * * MON-FRI)"
}

# Variable for EC2 tag key and value (default: "Dev_key" and "True")
variable "ec2_tag_key" {
  default = "Dev_key"
}

variable "ec2_tag_value" {
  default = "True"
}

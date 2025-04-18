terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = [pathexpand("~/.aws/credentials")]
  shared_config_files      = [pathexpand("~/.aws/config")]
}

data "aws_ecr_image" "name" {
  image_tag       = "latest"
  repository_name = aws_ecr_repository.name.name
}

resource "aws_ecr_repository" "name" {
  name         = var.repo_name
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "name" {
  repository = aws_ecr_repository.name.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 7 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 7
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_sns_topic" "name" {
  name = "send-mail"
}

resource "aws_iam_role" "name" {
  name                = "lambda-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  inline_policy {
    name = "trigger-sns"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublishSNSMessage",
          "Effect" : "Allow",
          "Action" : "sns:Publish",
          "Resource" : aws_sns_topic.name.arn
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lambda_function" "name" {
  function_name    = var.lambda_name
  role             = aws_iam_role.name.arn
  image_uri        = format("%s:latest", aws_ecr_repository.name.repository_url)
  package_type     = "Image"
  source_code_hash = replace(data.aws_ecr_image.name.image_digest, "sha256:", "")

  environment {
    variables = {
      "AWS_SNS_TOPIC_ARN" = aws_sns_topic.name.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "name" {
  name                = "stock-trigger"
  schedule_expression = var.event_rule_schedule_expression
}

resource "aws_cloudwatch_event_target" "name" {
  rule  = aws_cloudwatch_event_rule.name.name
  arn   = aws_lambda_function.name.arn
  input = jsonencode(yamldecode(file("check-links.yaml")))
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.name.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.name.arn
}

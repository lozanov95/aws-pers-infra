variable "region" {
  description = "The region of the deployment."
}

variable "repo_name" {
  description = "The ECR repository name."
}

variable "lambda_name" {
  description = "The name of your lambda function."
}

variable "event_rule_schedule_expression" {
  description = "The event rule shedule expression for your lambda function."
  default     = "cron(0 8 * * ? *)"
}

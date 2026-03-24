variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix for resource names."
  type        = string
  default     = "nhl-excit-o-meter-data"
}

variable "lambda_version" {
  description = "Version tag for Lambda deployment."
  type        = string
}

variable "lambda_sched_expr" {
  description = "Schedule expression for lambda"
  type        = string
}


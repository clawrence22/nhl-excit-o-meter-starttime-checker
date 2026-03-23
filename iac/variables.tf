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

variable "app_image" {
  description = "Container image URI in ECR."
  type        = string
  default     = "871806636838.dkr.ecr.us-east-1.amazonaws.com/nhl-excit-o-meter-starttime-checker:latest"
}


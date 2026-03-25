# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com","scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data aws_iam_policy_document lambda_policy {
  statement {
    effect = "Allow"

    actions = [
      "lambda:*",
      "scheduler:Create*",
      "scheduler:Get*",
      "scheduler:List*",
      "scheduler:Update*",
      "scheduler:Delete*",
      "iam:PassRole"
    ]

    resources = [aws_lambda_function.mylambda.arn,"arn:aws:scheduler:us-east-1:871806636838:schedule/default/NHLGameStartTimeTrigger","arn:aws:iam::871806636838:role/nhl-excit-o-meter-starttime-checker-role"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "nhl-excit-o-meter-starttime-checker-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach AWS Managed policy to the role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_policy_attachment" {
  name   = "nhl-excit-o-meter-starttime-checker-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# S3 bucket for Lambda deployment
resource "aws_s3_bucket" "lambda_deploy" {
  bucket = "${var.project_name}-lambda-deploy"
}

resource "aws_lambda_function" "mylambda" {
  function_name = "nhl-excit-o-meter-starttime-checker"
  role          = aws_iam_role.lambda.arn
  package_type  = "Zip"
  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  s3_bucket     = aws_s3_bucket.lambda_deploy.bucket
  s3_key        = "lambda_function-${var.lambda_version}.zip"

  memory_size = 512
  timeout     = 60
}

# DLQ for Scheduler
resource "aws_sqs_queue" "scheduler_dlq" {
  name = "${var.project_name}-scheduler-dlq"
}


# Scheduler to trigger Lambda
resource "aws_scheduler_schedule" "start_lambda" {
  name       = "start_lambda"
  group_name = "default"

 

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(${var.lambda_sched_expr})"
  schedule_expression_timezone = "America/Phoenix"
  target {
    arn      = aws_lambda_function.mylambda.arn
    role_arn = aws_iam_role.lambda.arn
    dead_letter_config {
      arn = aws_sqs_queue.scheduler_dlq.arn
    }
  }
}

# Cloud watch log group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {  
  name              = "/aws/lambda/${var.project_name}"
  retention_in_days = 7
}


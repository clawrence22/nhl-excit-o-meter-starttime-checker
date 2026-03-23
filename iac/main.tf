# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "nhl-excit-o-meter-starttime-checker-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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
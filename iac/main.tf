#ecr for image storage
resource "aws_ecr_repository" "ecr" {
  name = "${var.project_name}"
}

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

#iam policy for ecr access
data "aws_iam_policy_document" "ecr_access" {
  statement {
    effect = "Allow" 
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow" 
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["${aws_ecr_repository.ecr.arn}"]
  }
}

resource "aws_iam_policy" "ecr_access" {
  name   = "ECRAccessPolicy"
  policy = data.aws_iam_policy_document.ecr_access.json
  
}

resource "aws_iam_role_policy_attachment" "ecr-attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ecr_access.arn
}

resource "aws_lambda_function" "mylambda" {
  function_name = "nhl-excit-o-meter-starttime-checker"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = "${var.app_image}"

  memory_size = 512
  timeout     = 30

  architectures = ["arm64"] # Graviton support for better price/performance
}
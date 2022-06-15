data "aws_iam_policy_document" "allow_lambda_to_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "allow_sqs_consumer_actions" {
  statement {
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_sqs_producer_actions" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "producer_lambda" {
  name = "producer-test-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.allow_lambda_to_assume_role.json

  tags = merge(tomap({
    "Name" : "iam_role-producer_test_lambda",
    "Function" : "Producer Test Lambda Role"
  }), local.default_tags)
}

resource "aws_iam_role_policy_attachment" "producer_lambda_policy_attachment" {
  role       = aws_iam_role.producer_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "producer_lambda_role_sqs_producer_policy" {
  name   = "producer-test-lambda-allow-SQS-producer-permissions"
  role   = aws_iam_role.producer_lambda.id
  policy = data.aws_iam_policy_document.allow_sqs_producer_actions.json
}

resource "aws_iam_role" "consumer_lambda" {
  name = "consumer-test-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.allow_lambda_to_assume_role.json

  tags = merge(tomap({
    "Name" : "iam_role-consumer_test_lambda",
    "Function" : "Producer Test Lambda Role"
  }), local.default_tags)
}

resource "aws_iam_role_policy_attachment" "consumer_lambda_policy_attachment" {
  role       = aws_iam_role.consumer_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "find_alerts_lambda_role_sqs_consumer_policy" {
  name   = "consumer-test-lambda-allow-SQS-consumer-permissions"
  role   = aws_iam_role.consumer_lambda.id
  policy = data.aws_iam_policy_document.allow_sqs_consumer_actions.json
}



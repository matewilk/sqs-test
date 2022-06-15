locals {
  runtime               = "nodejs14.x"
  node_modules_zip_path = "${path.module}/../dist/layers/dependency_layer.zip"
  producer_timeout      = 900
  consumer_timeout      = 60
  producer_lambda_dist  = "${path.module}/../dist/lambdas/producer.zip"
  consumer_lambda_dist  = "${path.module}/../dist/lambdas/consumer.zip"
}

resource "aws_lambda_layer_version" "dependency_layer" {
  filename            = local.node_modules_zip_path
  layer_name          = "mat-wilk-sqs-test-deps-layer"
  description         = "Provides node_modules to the lambdas for mat-wilk-test"
  compatible_runtimes = [local.runtime]
  source_code_hash    = filebase64sha256(local.node_modules_zip_path)
}

resource "aws_lambda_function" "producer_lambda" {
  function_name = "producer-test-lambda"
  filename      = local.producer_lambda_dist
  role          = aws_iam_role.producer_lambda.arn
  handler       = "producer.handler"
  memory_size   = 1024

  source_code_hash = filebase64sha256(local.producer_lambda_dist)
  runtime          = local.runtime
  timeout          = local.producer_timeout

  layers = flatten([aws_lambda_layer_version.dependency_layer.arn])

  environment {
    variables = {
      ENV_NAME      = local.default_tags.Environment
      SQS_QUEUE_URL = aws_sqs_queue.test_sqs_queue.id
    }
  }
}

resource "aws_lambda_function" "consumer_lambda" {
  function_name = "consumer-test-lambda"
  filename      = local.consumer_lambda_dist
  role          = aws_iam_role.consumer_lambda.arn
  handler       = "consumer.handler"

  source_code_hash = filebase64sha256(local.consumer_lambda_dist)
  runtime          = local.runtime
  timeout          = local.consumer_timeout
}

resource "aws_lambda_event_source_mapping" "consumer_source_mapping" {
  event_source_arn = aws_sqs_queue.test_sqs_queue.arn
  function_name    = aws_lambda_function.consumer_lambda.arn
  batch_size       = 1
}

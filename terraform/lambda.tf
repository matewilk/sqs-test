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
  handler       = "newrelic-lambda-wrapper.handler"
  memory_size   = 1024

  source_code_hash = filebase64sha256(local.producer_lambda_dist)
  runtime          = local.runtime
  timeout          = local.producer_timeout

  layers = flatten([
    "arn:aws:lambda:eu-west-2:451483290750:layer:NewRelicNodeJS14X:58",
    aws_lambda_layer_version.dependency_layer.arn
  ])

  environment {
    variables = {
      ENV_NAME                              = local.default_tags.Environment
      SQS_QUEUE_URL                         = aws_sqs_queue.test_sqs_queue.id
      NEW_RELIC_ACCOUNT_ID                  = local.new_relic_account_id
      NEW_RELIC_LICENSE_KEY                 = local.new_relic_license_key
      NEW_RELIC_LAMBDA_HANDLER              = "producer/index.handler"
      LAMBDA_NAME                           = "producer"
      NEW_RELIC_DISTRIBUTED_TRACING_ENABLED = true
      NEW_RELIC_SPAN_EVENTS_ENABLED         = true
    }
  }

  tags = merge(tomap({
    "Name" : "Producer lambda",
    "Function" : "Sends messages to a queue",
    "Description" : "This lambda sends messages to test-sqs-queue",
  }), local.default_tags)
}

resource "aws_lambda_function" "producer_lambda_2" {
  function_name = "producer-test-lambda-2"
  filename      = local.producer_lambda_dist
  role          = aws_iam_role.producer_lambda.arn
  handler       = "newrelic-lambda-wrapper.handler"
  memory_size   = 1024

  source_code_hash = filebase64sha256(local.producer_lambda_dist)
  runtime          = local.runtime
  timeout          = local.producer_timeout

  layers = flatten([
    "arn:aws:lambda:eu-west-2:451483290750:layer:NewRelicNodeJS14X:58",
    aws_lambda_layer_version.dependency_layer.arn
  ])

  environment {
    variables = {
      ENV_NAME                              = local.default_tags.Environment
      SQS_QUEUE_URL                         = aws_sqs_queue.test_sqs_queue_2.id
      NEW_RELIC_ACCOUNT_ID                  = local.new_relic_account_id
      NEW_RELIC_LICENSE_KEY                 = local.new_relic_license_key
      NEW_RELIC_LAMBDA_HANDLER              = "producer/index.handler2"
      LAMBDA_NAME                           = "producer2"
      NEW_RELIC_DISTRIBUTED_TRACING_ENABLED = true
      NEW_RELIC_SPAN_EVENTS_ENABLED         = true
    }
  }

  tags = merge(tomap({
    "Name" : "Producer lambda 2",
    "Function" : "Sends messages to a queue 2",
    "Description" : "This lambda sends messages to test-sqs-queue-2",
  }), local.default_tags)
}

resource "aws_lambda_function" "consumer_lambda" {
  function_name = "consumer-test-lambda"
  filename      = local.consumer_lambda_dist
  role          = aws_iam_role.consumer_lambda.arn
  handler       = "newrelic-lambda-wrapper.handler"

  source_code_hash = filebase64sha256(local.consumer_lambda_dist)
  runtime          = local.runtime
  timeout          = local.consumer_timeout

  layers = flatten([
    "arn:aws:lambda:eu-west-2:451483290750:layer:NewRelicNodeJS14X:58",
    aws_lambda_layer_version.dependency_layer.arn,
  ])

  environment {
    variables = {
      ENV_NAME                              = local.default_tags.Environment
      SQS_QUEUE_URL                         = aws_sqs_queue.test_sqs_queue.id
      NEW_RELIC_ACCOUNT_ID                  = local.new_relic_account_id
      NEW_RELIC_LICENSE_KEY                 = local.new_relic_license_key
      NEW_RELIC_LAMBDA_HANDLER              = "consumer/index.handler"
      LAMBDA_NAME                           = "consumer"
      NEW_RELIC_DISTRIBUTED_TRACING_ENABLED = true
      NEW_RELIC_SPAN_EVENTS_ENABLED         = true
    }
  }
}

resource "aws_lambda_event_source_mapping" "consumer_source_mapping" {
  event_source_arn = aws_sqs_queue.test_sqs_queue.arn
  function_name    = aws_lambda_function.consumer_lambda.arn
  batch_size       = 1
}

resource "aws_lambda_event_source_mapping" "consumer_source_mapping_2" {
  event_source_arn = aws_sqs_queue.test_sqs_queue_2.arn
  function_name    = aws_lambda_function.consumer_lambda.arn
  batch_size       = 1
}

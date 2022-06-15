locals {
  queue_timeout = local.producer_timeout * 6
}

resource "aws_sqs_queue" "test_sqs_queue" {
  name                        = "test-sqs-queue"
  fifo_queue                  = false
  content_based_deduplication = false
  visibility_timeout_seconds  = local.queue_timeout
  redrive_policy = jsonencode({
    maxReceiveCount     = 5
    deadLetterTargetArn = aws_sqs_queue.test_sqs_queue_dead_letter.arn
  })

  tags = merge(tomap({
    "Name" : "test-sqs-queue",
    "Function" : "Test SQS queue",
    "Description" : "This queue receives events from producert-test-lambda",
  }), local.default_tags)
}

resource "aws_sqs_queue" "test_sqs_queue_dead_letter" {
  name                        = "test-sqs-queue-dead-letter"
  fifo_queue                  = false
  content_based_deduplication = false
  visibility_timeout_seconds  = local.queue_timeout

  tags = merge(tomap({
    "Name" : "test-sqs-queue",
    "Function" : "Test SQS queue",
    "Description" : "This queue receives failing messages from test-sqs-queue SQS gueue",
  }), local.default_tags)
}

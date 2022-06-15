terraform {
  backend "s3" {
    bucket = "mat-wilk-terraform-bucket"
    key    = "states/sqs-test"
    region = "eu-west-2"
  }
}

# New Relic AWS Distributed Tracing Integration
This repo contains an example of AWS Lambda -> SQS -> Lambda New Relic Distributed Tracing integration.

It contains the infrastructure under `/terraform` directory and the architecture of the infrastructure is described below.

## Architecture

The `terraform` deployment creates the following AWS architecture (with the names of components depicted in the chart)

![Lambda_NewRelic_DT drawio](https://user-images.githubusercontent.com/6328360/176427278-916aa432-d8c2-4aeb-a104-07285211880f.png)

- There are two `producer` lambdas, two `sqs` queues via which the `producer` lambdas send messages to the `consumer`
- Both `producer`s send messages in batches
- `consumer` is set as a `lambda trigger ` for both `sqs` queues
- `consumer` ingests messages individually (batch size on the lambda is set to `1`)


## How to run

### Prerequisites
- [AWS configuration and credetnails setup](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [New Relic Account](https://docs.newrelic.com/docs/accounts/accounts-billing/account-setup/create-your-new-relic-account/) -  [and its number (ID)](https://docs.newrelic.com/docs/accounts/accounts-billing/account-structure/account-id/)
- [New Relic License Key](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/#overview-keys)
- [AWS Lambda monitoring integration](https://docs.newrelic.com/docs/infrastructure/amazon-integrations/aws-integrations-list/aws-lambda-monitoring-integration/)
- [Node and NPM installed](https://nodejs.org/en/download/)
- [Terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli)


### Build
Before deploying navigate to `/terraform/local.tf` and asign appropriate values to New Relic `account_id` and `license_key` variables.
```
new_relic_account_id  = ""
new_relic_license_key = ""
```

Run the following commands:
- `npm install` - to install all the dependencies
- `npm run build` - to build and package all the lambda functions to be ready for deployment

### Deploy
In a terminal window navigate to `/terraform` and run
- `terraform plan` - to see deployment plan
- `terraform apply` - to deploy infrastructure to AWS

### Usage
Login to AWS web console and navigate to one of the functions
- `producer-test-lambda`
- `producer-test-lambda-2`

Navigate to `Test` tab and use the following Event Json to send evnets from a `producer` lambda:
```
{
  "count": 5,
  "batch": true
}
```
![Screenshot 2022-06-29 at 13 25 48](https://user-images.githubusercontent.com/6328360/176435809-70892c2c-f853-4a20-9a60-db8cc5b9d48b.png)

`count` paramter indicates the number of messages to be sent from a `producer` function via an `sqs` queue to the `consumer` function.
`batch` paramter indicates whether to send messages in batches of `10` (use batches only for the time being! - `batch: true`)

Use `Monitor` tabs of the components (`lambdas` and `sqs` queues) or CloudWatch Logs to confirm that the messages were sent/received as expected.

## Observability with New Relic
In New Relic UI navigate to `Explorer` and search for `consumer-test-lambda`
<img width="1662" alt="Screenshot 2022-06-29 at 13 32 28" src="https://user-images.githubusercontent.com/6328360/176436981-3be088ca-8970-4d30-ae5b-de26e98614ad.png">

Select the `lambda` and you should be able to see the `Summary` page
<img width="1654" alt="Screenshot 2022-06-29 at 13 36 23" src="https://user-images.githubusercontent.com/6328360/176437709-bf338050-9cfb-491d-838c-6aa7ee602fec.png">

Navigate to `Distributed Tracing` (in the left hend side menu)
<img width="1662" alt="Screenshot 2022-06-29 at 13 37 50" src="https://user-images.githubusercontent.com/6328360/176437988-1a9f5925-866b-4a34-bacb-70ddb6618643.png">

Select on of the `Trace Groups` and select a `trace`
<img width="1668" alt="Screenshot 2022-06-29 at 13 39 53" src="https://user-images.githubusercontent.com/6328360/176438394-6b1359c1-84cd-41de-a411-240e465c33c5.png">

Individual `Span`s and the `trace map` is visible and shows the relationship between `lambdas` (and `queues` when spans are expanded)
<img width="1666" alt="Screenshot 2022-06-29 at 13 42 04" src="https://user-images.githubusercontent.com/6328360/176438796-2aab9db2-13db-4a86-bb35-a099ad696560.png">

## Cleanup

Run `terraform destroy` to remove infrastructure from the AWS account.
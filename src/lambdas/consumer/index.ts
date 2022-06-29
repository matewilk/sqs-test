import { SQSEvent } from "aws-lambda";
import newrelic, { TransactionHandle } from "newrelic";

const randomIntBetween = (min, max) =>
  Math.floor(Math.random() * (max - min + 1) + min);

const delay = (ms) => new Promise((res) => setTimeout(res, ms));

const getNewRelicTransaction = () => {
  const transaction: TransactionHandle = newrelic.getTransaction();
  return transaction;
};

const acceptNewRelicDTHeaders = async (
  event: SQSEvent,
  transaction: TransactionHandle
) => {
  await Promise.all(
    event.Records.map(async (r) => {
      if (r.messageAttributes.NRDT) {
        const dtHeaders = r.messageAttributes.NRDT.stringValue;
        console.log("DT-HEADERS", dtHeaders);
        // @ts-ignore
        const traceContext = JSON.parse(dtHeaders);

        transaction.acceptDistributedTraceHeaders("Queue", traceContext);
      }
    })
  );
};

export const handler = async (event: SQSEvent) => {
  console.log(`Consumer received event: ${JSON.stringify(event)}`);
  const randomInterval = randomIntBetween(100, 10000);
  console.log(`wait time set to ${randomInterval}ms`);
  await delay(randomInterval);

  const transaction = getNewRelicTransaction();

  console.log("Finished lambda");

  acceptNewRelicDTHeaders(event, transaction);
  newrelic.addCustomAttribute("queue", "test-sqs-queue-consumer");

  transaction.end();

  console.log("Transaction End");
};

import { SQSEvent } from "aws-lambda";

const randomIntBetween = (min, max) =>
  Math.floor(Math.random() * (max - min + 1) + min);

const delay = (ms) => new Promise((res) => setTimeout(res, ms));

export const handler = async (event: SQSEvent) => {
  console.log(`Consumer received event: ${JSON.stringify(event)}`);
  const randomInterval = randomIntBetween(100, 10000);
  console.log(`wait time set to ${randomInterval}ms`);
  await delay(randomInterval);
  console.log("Finished lambda");
};

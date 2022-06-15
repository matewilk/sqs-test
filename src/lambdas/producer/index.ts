import {
  SQSClient,
  SendMessageCommand,
  SendMessageCommandInput,
  SendMessageBatchCommand,
  SendMessageBatchCommandInput,
} from "@aws-sdk/client-sqs";
import { v4 as uuid } from "uuid";

const sqsClient = new SQSClient({
  region: "eu-west-2",
  maxAttempts: 3,
});

type MessageBatch = {
  Id: string;
  MessageBody: string;
};

const CHUNK_SIZE: number = 10;

// @ts-ignore
const calculateFullResult = (result) => {
  return result.reduce(
    (acc, item) => {
      console.log("RESULT ITEM:", {
        // @ts-ignore
        Successful: item?.result?.Successful,
        // @ts-ignore
        Failed: item?.result?.Failed,
      });
      acc.successful += item === undefined ? 0 : item?.successful || 0;
      acc.failed += item === undefined ? 10 : item?.failed || 0;
      return acc;
    },
    { successful: 0, failed: 0 }
  );
};

const generateNewRelicTraceContextJson = () => {
  
}

const chunkArray = (inputArray: any[]) =>
  inputArray.reduce((all, one, i) => {
    const ch = Math.floor(i / CHUNK_SIZE);
    all[ch] = [].concat(all[ch] || [], one);
    return all;
  }, []);

const createMessagesBatch = (batch: any[]): MessageBatch[] => {
  return batch.map((item, index) => {
    return {
      Id: `messageId-${index}`, // Id needs to be unique within a request
      MessageBody: `Message ${item}`,
    };
  });
};

const sendMessage = async (message: string, messageGroupId: string) => {
  const input: SendMessageCommandInput = {
    QueueUrl: process.env.SQS_QUEUE_URL,
    MessageGroupId: messageGroupId,
    MessageAttributes: {

    },
    MessageBody: message,
    MessageDeduplicationId: uuid(),
  };
  const sendMessageCommand: SendMessageCommand = new SendMessageCommand(input);

  try {
    const result = await sqsClient.send(sendMessageCommand);
    console.log("messageCommandInput (success):", input);
    console.log("send result:", result);
    return result;
  } catch (error) {
    console.log("messageCommandInput (error):", input);
    console.log(`send sqs message error: ${error}`);
  }
};

const sendBatchMessage = async (batch: MessageBatch[]) => {
  const input: SendMessageBatchCommandInput = {
    QueueUrl: process.env.SQS_QUEUE_URL,
    Entries: batch,
  };

  const sendMessageBatchCommand: SendMessageBatchCommand =
    new SendMessageBatchCommand(input);

  try {
    const result = await sqsClient.send(sendMessageBatchCommand);
    // return Promise.resolve({
    //   result,
    //   failed: result.Failed?.length || 0,
    //   successful: result.Successful?.length || 0,
    // });
    console.log(result);
    return result;
  } catch (error) {
    console.log(`send sqs batch message error: ${error}`);
  }
};

type Event = {
  count: number;
  batch: boolean;
};

export const handler = async (event: Event) => {
  console.log(`Triggering ${event.count} messages`);
  const batch = event.batch || false;
  const iterable = Array.from(Array(event.count).keys());

  if (batch) {
    const chunked = chunkArray(iterable);
    const allBatches = chunked.map(async (batch) => {
      const messagesBatch = createMessagesBatch(batch);
      return await sendBatchMessage(messagesBatch);
    });

    await Promise.all(allBatches);
    // const fullResult = calculateFullResult(result);
    // console.log(`FULL RESULT: ${JSON.stringify(fullResult)}`);
  } else {
    const all = await iterable.map(async (_, index) => {
      try {
        const groupId = Math.round(index / 100); // generate new ID every 100 messages
        await sendMessage(`Test message ${index}`, `group-${groupId}`);
      } catch (error) {
        console.log(`lambda handler send message error: ${error}`);
      }
    });

    await Promise.all(all);
  }
};

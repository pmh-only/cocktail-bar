import { KinesisClient, PutRecordCommand } from "@aws-sdk/client-kinesis"; // ES Modules import

export const handler = async (event) => {
  const client = new KinesisClient();
  const input = { // PutRecordInput
    StreamName: "order-stream",
    Data: Buffer.from(JSON.stringify(event)),  // required
    PartitionKey: Date.now().toString(), // required
  };
  const command = new PutRecordCommand(input);
  const response = await client.send(command);
};

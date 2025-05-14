import { KinesisClient, PutRecordsCommand } from "@aws-sdk/client-kinesis"; // ES Modules import
import crypto from 'node:crypto'

export const handler = async (event) => {
  const client = new KinesisClient({})
  const input = {
    Records: [
      {
        Data: new TextEncoder().encode(event.body),
        PartitionKey: crypto.randomUUID(),
      }
    ],
    StreamARN: "arn:aws:kinesis:ap-northeast-2:648911607072:stream/wsi-data-stream"
  }
  
  const command = new PutRecordsCommand(input)
  const response = await client.send(command)

  return {
    statusCode: 200,
    body: JSON.stringify({
      success: true
    })
  }
}

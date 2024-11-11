import { TextractClient, StartDocumentTextDetectionCommand } from "@aws-sdk/client-textract"
import { extname } from 'path'

export const handler = async (event) => {
  console.log(JSON.stringify(event))
  const client = new TextractClient({
    region: 'ap-northeast-2'
  });
  
  for (const record of event.Records) {
    const id = `${record.s3.object.key.replace(/\//, '')}-${Date.now()}`
    const input = {
      DocumentLocation: {
        S3Object: {
          Bucket: record.s3.bucket.name,
          Name: record.s3.object.key.replace(/\+/g, ' ')
        },
      },
      OutputConfig: {
        S3Bucket: record.s3.bucket.name,
        S3Prefix: `output/${id}/`
      }
    }

    console.log(input)

    const command = new StartDocumentTextDetectionCommand(input)
    await client.send(command)
  }
}

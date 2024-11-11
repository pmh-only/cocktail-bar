import { TranscribeClient, StartTranscriptionJobCommand } from "@aws-sdk/client-transcribe"; // ES Modules import
import { extname } from 'path'

export const handler = async (event) => {
  console.log(JSON.stringify(event))
  const client = new TranscribeClient({})

  for (const record of event.Records) {
    const id = `${record.s3.object.key.replace(/\//, '')}-${Date.now()}`
    const input = {
      TranscriptionJobName: id,
      MediaFormat: extname(record.s3.object.key).replace('.', ''),
      Media: {
        MediaFileUri: `s3://${record.s3.bucket.name}/${record.s3.object.key}`
      },
      OutputBucketName: record.s3.bucket.name,
      OutputKey: `output/${id}`,
      IdentifyLanguage: true,
    };
  
    const command = new StartTranscriptionJobCommand(input);
    await client.send(command);
  }
}

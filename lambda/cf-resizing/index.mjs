import sharp from 'sharp'
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'

export const handler = async (event) => {
  const request = event.Records[0].cf.request
  const searchParams = new URLSearchParams(request.querystring)

  const width = parseInt(searchParams.get('width')) || undefined
  const height = parseInt(searchParams.get('height')) || undefined

  const client = new S3Client({});
  const command = new GetObjectCommand({
    Bucket: 'shutupandtakemybucket',
    Key: request.uri.replace('/', '')
  })

  const object = await client.send(command)
  const objectBody = await object.Body.transformToByteArray()
  
  const result = await sharp(objectBody)
    .resize(width, height)
    .toBuffer()

  return {
    body: result.toString('base64'),
    bodyEncoding: 'base64',
    headers: {
      'Content-Type': [{
        value: object.ContentType
      }]
    },
    status: '200'
  }
}

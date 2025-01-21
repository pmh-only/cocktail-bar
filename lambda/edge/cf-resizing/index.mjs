import sharp from 'sharp'
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'

export const handler = async (event) => {
  const request = event.Records[0].cf.request
  const searchParams = new URLSearchParams(request.querystring)

  const width = parseInt(searchParams.get('width'))
  const height = parseInt(searchParams.get('height'))

  if (!request.uri.startsWith('/images'))
    return request

  if (Number.isNaN(width) && Number.isNaN(height))
    return request

  const client = new S3Client({
    region: 'ap-northeast-2'
  })
  
  const command = new GetObjectCommand({
    Bucket: 'project-frontend20250121063308540100000002',
    Key: request.uri.replace('/', '')
  })
  
  const object = await client.send(command)
    .catch(() => undefined)

  if (object === undefined)
    return request

  if (!object.ContentType.startsWith('image/'))
    return request

  const objectBody = await object.Body.transformToByteArray()
  
  const result = await sharp(objectBody)
    .resize({
      width: Number.isNaN(width) ? undefined : width,
      height: Number.isNaN(height) ? undefined : height
    })
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

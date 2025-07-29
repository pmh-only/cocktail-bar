import boto3

s3 = boto3.client('s3', region_name='ap-northeast-2')
url = s3.generate_presigned_url(
  ClientMethod='put_object',
  Params={
    'Bucket': 'testing-18927389172893',
    'Key': 'file.txt'
  },
  ExpiresIn=900
)

print(url)

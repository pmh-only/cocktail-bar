import boto3
import datetime

def lambda_handler(event, context):
  s3 = boto3.client('s3')
  
  try:
    s3.create_bucket(
      Bucket=event['bucket'],
      CreateBucketConfiguration={
        'LocationConstraint': event['region'] })
  except:
    pass

  s3.put_object(
    Bucket=event['bucket'],
    Key=datetime.datetime.now().strftime("%Y%m%d_%H%M%S_log.txt"),
    Body=event['text'].encode('utf-8'))

  return {
    'success': True
  }

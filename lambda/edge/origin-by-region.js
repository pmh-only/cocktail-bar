export const handler = (event, context) => {
  const request = event.Records[0].cf.request
  const region = context.invokedFunctionArn.split(':')[3]
  const bucketName = {
    'us-east-1': 'us-frontend-189273891723897',
    'ap-northeast-2': 'ap-frontend-1283791827389'
  }
    
  if (region) {
    request.origin.s3.region = region
    const domainName = `${bucketName[region]}.s3.${region}.amazonaws.com`
    request.origin.s3.domainName = domainName
    request.headers['host'] = [{ key: 'host', value: domainName }]
  }

  return request
}

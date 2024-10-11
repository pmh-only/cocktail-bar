import zlib from 'zlib'
import { IAMClient, DetachRolePolicyCommand } from '@aws-sdk/client-iam'
import { CloudWatchClient, PutMetricDataCommand } from "@aws-sdk/client-cloudwatch"

export const handler = async (event) => {
  if (!event.awslogs || !event.awslogs.data)
    return
    
  const iam = new IAMClient({});
  const cw = new CloudWatchClient({});
    
  const payload = Buffer.from(event.awslogs.data, 'base64')
  const logevents = JSON.parse(zlib.unzipSync(payload).toString()).logEvents

  for (const logevent of logevents) {
    const log = JSON.parse(logevent.message)
    const command = new DetachRolePolicyCommand({
      RoleName: log.requestParameters.roleName,
      PolicyArn: log.requestParameters.policyArn
    })
    
    await iam.send(command)
    
    const command2 = new PutMetricDataCommand({
      Namespace: 'test1',
      MetricData: [{
        MetricName: 'test1',
        Value: 1,
        Unit: 'Count'
      }]
    });
    await cw.send(command2)
  }
}

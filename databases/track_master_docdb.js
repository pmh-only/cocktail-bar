import { Route53Client, ChangeResourceRecordSetsCommand } from "@aws-sdk/client-route-53";

export const handler = async (event) => {
  const client = new Route53Client({ region: "us-east-1" });
  
  await Promise.all(event.Records.map((record) =>
    new Promise(async (resolve) => {
      const eventId = record.Sns.MessageAttributes.EventID.Value;
    
      if (eventId !== "RDS-EVENT-0238")
        return
    
      const params = {
        HostedZoneId: "Z04109492H1KVWZBDTQU6",
        ChangeBatch: {
          Changes: [
            {
              Action: "UPSERT",
              ResourceRecordSet: {
                Name: "failover.docdb.local",
                Type: "CNAME",
                TTL: 10,
                ResourceRecords: [{
                  Value: "project-docdb.cluster-cemltsgrnhrl.ap-northeast-2.docdb.amazonaws.com"
                }]
              }
            }
          ]
        }
      }
      
      const command = new ChangeResourceRecordSetsCommand(params)
      
      try {
        const response = await client.send(command)
        console.log("Record updated successfully:", response)
      } catch (error) {
        console.error("Failed to update record:", error)
      }
    })
  ))
}

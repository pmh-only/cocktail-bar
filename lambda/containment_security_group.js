import { EC2Client, DescribeSecurityGroupRulesCommand, RevokeSecurityGroupIngressCommand, RevokeSecurityGroupEgressCommand } from "@aws-sdk/client-ec2"

export const handler = async (event) => {
  const client = new EC2Client({})
  const input = {
    Filters: [
      {
        Name: "group-id",
        Values: [
          "sg-008f750b574388f3e"
        ]
      }
    ]
  }
  
  const command = new DescribeSecurityGroupRulesCommand(input)
  const { SecurityGroupRules }  = await client.send(command)
  
  const input2 = {
    GroupId: "sg-008f750b574388f3e",
    SecurityGroupRuleIds: SecurityGroupRules.filter(v => !v.IsEgress).map(v => v.SecurityGroupRuleId)
  }
  
  const command2 = new RevokeSecurityGroupIngressCommand(input2)
  await client.send(command2)
  
  const input3 = {
    GroupId: "sg-008f750b574388f3e",
    SecurityGroupRuleIds: SecurityGroupRules.filter(v => v.IsEgress).map(v => v.SecurityGroupRuleId)
  }
  
  const command3 = new RevokeSecurityGroupEgressCommand(input3)
  await client.send(command3)
}

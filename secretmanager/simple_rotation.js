import {
  SecretsManagerClient,
  GetRandomPasswordCommand,
  PutSecretValueCommand,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"

export const handler = async (event) => {
  const { SecretId, Step, ClientRequestToken } = event
  const client = new SecretsManagerClient({})

  if (Step !== "createSecret")
    return

  const command = new GetRandomPasswordCommand()
  const { RandomPassword } = await client.send(command)

  const command2 = new GetSecretValueCommand({
    SecretId
  })
  const { SecretString } = await client.send(command2)

  const command3 = new PutSecretValueCommand({
    SecretId,
    ClientRequestToken,
    SecretString: JSON.stringify({
      ...JSON.parse(SecretString),
      password: RandomPassword
    }),
    VersionStages: ['AWSCURRENT']
  })

  await client.send(command3)
}

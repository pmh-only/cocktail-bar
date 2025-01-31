import mysql from 'mysql'
import {
  SecretsManagerClient,
  GetRandomPasswordCommand,
  PutSecretValueCommand,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"

const ADMIN_SECRET_ID = process.env.ADMIN_SECRET_ID

export const handler = async (event) => {
  const { SecretId, Step, ClientRequestToken } = event
  const client = new SecretsManagerClient({})

  if (Step !== "createSecret")
    return

  const command = new GetRandomPasswordCommand()
  const { RandomPassword } = await client.send(command)

  
  const command4 = new GetSecretValueCommand({
    SecretId: ADMIN_SECRET_ID
  })
  const { SecretString: SecretString2 } = await client.send(command4)
  const SecretContent2 = JSON.parse(SecretString2)

  const command2 = new GetSecretValueCommand({
    SecretId
  })
  const { SecretString } = await client.send(command2)
  const SecretContent = JSON.parse(SecretString)

  const conn = mysql.createConnection({
    host: SecretContent.host,
    port: parseInt(SecretContent.port),
    user: SecretContent2.username,
    password: SecretContent2.password
  })

  conn.connect()
  conn.query(`ALTER USER ${SecretContent.username}@'%' IDENTIFIED BY ?`, [RandomPassword], function (error) {
    if (error) throw error
  })
  
  conn.end()

  const command3 = new PutSecretValueCommand({
    SecretId,
    ClientRequestToken,
    SecretString: JSON.stringify({
      ...SecretContent,
      password: RandomPassword
    }),
    VersionStages: ['AWSCURRENT']
  })

  await client.send(command3)
}

import mysql from 'mysql'
import {
  SecretsManagerClient,
  GetRandomPasswordCommand,
  PutSecretValueCommand,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"

const ADMIN_USER = process.env.ADMIN_USER ?? 'admin'
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'admin123!!'

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
  const SecretContent = JSON.parse(SecretString)

  const conn = mysql.createConnection({
    host: SecretContent.host,
    port: parseInt(SecretContent.port),
    user: ADMIN_USER,
    password: ADMIN_PASSWORD
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

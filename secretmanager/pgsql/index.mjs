import pg from 'pg'
import {
  SecretsManagerClient,
  GetRandomPasswordCommand,
  PutSecretValueCommand,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"

const ADMIN_USER = process.env.ADMIN_USER ?? 'postgres'
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

  const conn = new pg.Client({
    host: SecretContent.host,
    port: parseInt(SecretContent.port),
    user: ADMIN_USER,
    password: ADMIN_PASSWORD,
    ssl: {
      rejectUnauthorized: false
    }
  })

  await conn.connect()
  await conn.query(`ALTER USER ${SecretContent.username} WITH PASSWORD '${RandomPassword.replace(/'/g, "''")}'`)
  
  await conn.end()

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

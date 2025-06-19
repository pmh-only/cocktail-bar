import mysql from 'mysql'
import {
  SecretsManagerClient,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"
import { DynamoDBClient, GetItemCommand, PutItemCommand } from "@aws-sdk/client-dynamodb"; // ES Modules import

const ADMIN_SECRET_ID = "arn:aws:secretsmanager:ap-northeast-2:648911607072:secret:project-secret-qfBq2W"

const dynamodb = new DynamoDBClient();
const secretsmanager = new SecretsManagerClient();

export const handler = async (event) => {
  if (event.path === "/trip" && event.httpMethod === "GET") {
    const client = dynamodb
    const input = { // GetItemInput
      TableName: "trip", // required
      Key: { // Key // required
        "id": { // AttributeValue Union: only one key present
          S: event.queryStringParameters.id ?? ''
        },
      }
    };
    const command = new GetItemCommand(input);
    const response = await client.send(command);

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: !!response.Item,
        data: response.Item ? {
          id: response.Item.id.S,
          name: response.Item.name.S,
          duration: response.Item.duration.S,
        } : null
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }

  if (event.path === "/trip" && event.httpMethod === "POST") {
    const body = JSON.parse(event.body)
    const client = dynamodb;
    const input = { // PutItemInput
      TableName: "trip", // required
      Item: {
        "id": { S: body.id },
        "name": { S: body.name },
        "duration": { S: body.duration },
      }
    };
    const command = new PutItemCommand(input);
    const response = await client.send(command);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ ok: true }),
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }
  
  if (event.path === "/cost" && event.httpMethod === "GET") {
    const client = secretsmanager
    const command4 = new GetSecretValueCommand({
      SecretId: ADMIN_SECRET_ID
    })
    const { SecretString: SecretString2 } = await client.send(command4)
    const SecretContent2 = JSON.parse(SecretString2)

    const conn = mysql.createConnection({
      host: "project-rdsproxy.proxy-cemltsgrnhrl.ap-northeast-2.rds.amazonaws.com",
      port: 3306,
      user: SecretContent2.username,
      password: SecretContent2.password
    })
  
    conn.connect()
    const result = await new Promise((resolve, reject) => {
      conn.query('SELECT * FROM unicorn.cost WHERE id = ?',
        [event.queryStringParameters.id ?? ''],
        function (error, results, fields) {
        if (error) {
          reject(error)
          return
        }

        if (results.length === 0) {
          
          resolve({
            success: false
          })
          return
        }

        resolve({
          success: true,
          id: results[0].id,
          cost: results[0].cost
        })
      });
    })
    conn.end()

    return {
      statusCode: 200,
      body: JSON.stringify(result),
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }

  if (event.path === "/cost" && event.httpMethod === "POST") {
    const result = await fetch('http://project-webapp-nlb-ccaac2585e653a80.elb.ap-northeast-2.amazonaws.com/cost', {
      headers: {
        'Content-Type': 'application/json'
      },
      method: 'POST',
      body: event.body
    }).then((res) => res.text())

    return {
      statusCode: 200,
      body: result,
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }
}

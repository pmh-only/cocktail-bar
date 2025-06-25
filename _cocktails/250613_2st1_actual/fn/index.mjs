import mysql from 'mysql'
import {
  SecretsManagerClient,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager"
import { DynamoDBClient, GetItemCommand, PutItemCommand } from "@aws-sdk/client-dynamodb"; // ES Modules import
import crypto from 'crypto'

const ADMIN_SECRET_ID = "arn:aws:secretsmanager:ap-northeast-2:213350056695:secret:unicorn-sSKM9u"

const dynamodb = new DynamoDBClient();
const secretsmanager = new SecretsManagerClient();

export const handler = async (event) => {
  if (event.path === "/book" && event.httpMethod === "GET") {
    const client = dynamodb
    const input = { // GetItemInput
      TableName: "booking", // required
      Key: { // Key // required
        "bookId": { // AttributeValue Union: only one key present
          S: event.queryStringParameters.bookId ?? ''
        },
      }
    };
    const command = new GetItemCommand(input);
    const response = await client.send(command);

    if (!response.Item) {
      
      return {
        statusCode: 404,
        body: JSON.stringify({
          success: false
        })
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        bookId: response.Item.bookId?.S,
        status: response.Item.status?.S,
        confirmed: response.Item.confirmed?.S
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }

  if (event.path === "/book" && event.httpMethod === "POST") {
    const body = JSON.parse(event.body)
    const bookId = crypto.randomUUID()
    const client = dynamodb;
    const input = { // PutItemInput
      TableName: "booking", // required
      Item: {
        "bookId": { S: bookId },
        "status": { S: "pending" },
        "hash": { S: "" },
      }
    };
    const command = new PutItemCommand(input);
    const response = await client.send(command);
    
    const command4 = new GetSecretValueCommand({
      SecretId: ADMIN_SECRET_ID
    })
    const { SecretString: SecretString2 } = await secretsmanager.send(command4)
    const SecretContent2 = JSON.parse(SecretString2)

    const conn = mysql.createConnection({
      host: "project-rdsproxy.proxy-cemltsgrnhrl.ap-northeast-2.rds.amazonaws.com",
      port: 3306,
      user: SecretContent2.username,
      password: SecretContent2.password
    })
  
    conn.connect()
    const result = await new Promise((resolve, reject) => {
      conn.query('INSERT INTO booking values (?, ?, ?, ?)',
        [bookId, body.userId, body.packageId, body.travelDate],
        function (error, results, fields) {
        resolve()
        return
      });
    })
    conn.end()


    return {
      statusCode: 200,
      body: JSON.stringify({ bookId }),
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }

  if (event.path === "/payment" && event.httpMethod === "POST") {
    const result = await fetch('http://project-webapp-nlb-ccaac2585e653a80.elb.ap-northeast-2.amazonaws.com/cost', {
      headers: {
        'Content-Type': 'application/json'
      },
      method: 'POST',
      body: event.body
    }).then((res) => res.json())
    
    
    const client = dynamodb;
    const input = { // PutItemInput
      TableName: "booking", // required
      Item: {
        "bookId": { S: bookId },
        "status": { S: "confirmed" },
        "hash": { S: result.hash },
      }
    };
    const command = new PutItemCommand(input);
    const response = await client.send(command);

    return {
      statusCode: 200,
      body: result,
      headers: {
        'Content-Type': 'application/json'
      }
    }
  }
}

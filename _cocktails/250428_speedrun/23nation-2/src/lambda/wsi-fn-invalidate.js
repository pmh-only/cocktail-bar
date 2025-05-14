import { CloudFrontClient, CreateInvalidationCommand } from "@aws-sdk/client-cloudfront"; // ES Modules import
import crypto from 'crypto'

export const handler = async (event) => {
  console.log(JSON.stringify(event))
  const data = event.Records.map(JkhQoj => JkhQoj.s3.object.key);

  // const { CloudFrontClient, CreateInvalidationCommand } = require("@aws-sdk/client-cloudfront"); // CommonJS import
  const client = new CloudFrontClient({});
  const input = { // CreateInvalidationRequest
    DistributionId: "EHPRMNHI51203", // required
    InvalidationBatch: { // InvalidationBatch
      Paths: { // Paths
        Quantity: data.length, // required
        Items: data.map((v) => `/${v}`),
      },
      CallerReference: crypto.randomUUID(), // required
    },
  };
  const command = new CreateInvalidationCommand(input);
  const response = await client.send(command);
  // { // CreateInvalidationResult
  //   Location: "STRING_VALUE",
  //   Invalidation: { // Invalidation
  //     Id: "STRING_VALUE", // required
  //     Status: "STRING_VALUE", // required
  //     CreateTime: new Date("TIMESTAMP"), // required
  //     InvalidationBatch: { // InvalidationBatch
  //       Paths: { // Paths
  //         Quantity: Number("int"), // required
  //         Items: [ // PathList
  //           "STRING_VALUE",
  //         ],
  //       },
  //       CallerReference: "STRING_VALUE", // required
  //     },
  //   },
  // };
  
  
};

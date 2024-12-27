import { CloudFrontClient, CreateInvalidationCommand } from "@aws-sdk/client-cloudfront"; // ES Modules import

export const handler = async (event) => {
  console.log(JSON.stringify(event))

  const client = new CloudFrontClient({});
  const input = { // CreateInvalidationRequest
    DistributionId: "E3BFCZT5AEVOJ0", // required
    InvalidationBatch: { // InvalidationBatch
      Paths: { // Paths
        Quantity: 1, // required
        Items: [ // PathList
          "/*",
        ],
      },
      CallerReference: Date.now().toString()
    },
  };
  const command = new CreateInvalidationCommand(input);
  await client.send(command);
    // TODO implement
  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda!'),
  };
  return response;
};

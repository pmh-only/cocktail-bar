import { CloudFrontClient, CreateInvalidationCommand } from "@aws-sdk/client-cloudfront"; // ES Modules import
export const handler = async (event) => {
  const keys = event.Records.map(XGbNLs => '/' + XGbNLs.s3.object.key)

  const client = new CloudFrontClient({
    region: 'us-east-1'
  });
  const input = { // CreateInvalidationRequest
    DistributionId: "ERVNV741UCH4A", // required
    InvalidationBatch: { // InvalidationBatch
      Paths: { // Paths
        Quantity: keys.length, // required
        Items: keys,
      },
      CallerReference: Math.random().toString(), // required
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


}

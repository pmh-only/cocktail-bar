// Import necessary AWS SDK clients and commands
import {
  GlueClient,
  GetPartitionCommand,
  GetTableCommand,
  CreatePartitionCommand,
} from '@aws-sdk/client-glue'

// Initialize the Glue client
const glueClient = new GlueClient({ region: process.env.AWS_REGION })

export const handler = async (event) => {
  // Retrieve Glue Database and Table names from environment variables
  const DATABASE_NAME = process.env.GLUE_DATABASE_NAME
  const TABLE_NAME = process.env.GLUE_TABLE_NAME

  // Iterate over each S3 event record
  for (const record of event.Records) {
    try {
      // Extract bucket name and object key from the event
      const sourceKey = decodeURIComponent(
        record.s3.object.key.replace(/\+/g, ' ')
      )

      // Assuming the object key structure: folder_name/YYYY/MM/DD/HH/sample.json
      const keyParts = sourceKey.split('/')

      // Adjust the slice indices based on your actual key structure
      // Here, it removes the first 5 parts and the last part (filename)
      const partitionValues = keyParts.slice(5, -1) // ['YYYY', 'MM', 'DD', 'HH']
      console.log('Partition Values:', partitionValues)

      // Prepare parameters to get the partition
      const getPartitionParams = {
        DatabaseName: DATABASE_NAME,
        TableName: TABLE_NAME,
        PartitionValues: partitionValues,
      }

      try {
        // Attempt to retrieve the partition
        const getPartitionCommand = new GetPartitionCommand(getPartitionParams)
        await glueClient.send(getPartitionCommand)
        console.log('Glue partition already exists for:', partitionValues)
      } catch (error) {
        // If the partition does not exist, create it
        if (error.name === 'EntityNotFoundException') {
          console.log('Partition not found. Creating a new partition.')

          // Retrieve table details to get the storage descriptor
          const getTableParams = {
            DatabaseName: DATABASE_NAME,
            Name: TABLE_NAME,
          }
          const getTableCommand = new GetTableCommand(getTableParams)
          const tableResponse = await glueClient.send(getTableCommand)
          const storageDescriptor = tableResponse.Table.StorageDescriptor

          // Create a new storage descriptor for the partition
          const customStorageDescriptor = { ...storageDescriptor }

          // Construct the new location by appending partition values
          let newLocation = storageDescriptor.Location
          if (!newLocation.endsWith('/')) {
            newLocation += '/'
          }
          newLocation += partitionValues.join('/') + '/'
          customStorageDescriptor.Location = newLocation

          // Prepare parameters to create the new partition
          const createPartitionParams = {
            DatabaseName: DATABASE_NAME,
            TableName: TABLE_NAME,
            PartitionInput: {
              Values: partitionValues,
              StorageDescriptor: customStorageDescriptor,
            },
          }

          // Create the partition
          const createPartitionCommand = new CreatePartitionCommand(
            createPartitionParams
          )
          await glueClient.send(createPartitionCommand)
          console.log('Successfully created Glue partition:', partitionValues)
        } else {
          // If the error is something else, log it
          console.error('Error retrieving partition:', error)
        }
      }
    } catch (error) {
      // Handle any unexpected errors
      console.error('Error processing record:', error)
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify('Partition processing completed.')
  }
}

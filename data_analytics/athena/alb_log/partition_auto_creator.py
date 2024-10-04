import boto3
import urllib.parse
import os
import copy

def lambda_handler(event, context):

     for record in event['Records']:
        try:
            source_bucket = record['s3']['bucket']['name']
            source_key = urllib.parse.unquote_plus(
                record['s3']['object']['key'], encoding='utf-8')
            source_file_name = os.path.basename(source_key)

            # Extract the Glue Database and Table name from Environment Variables
            DATABASE_NAME = '<GLUE_DATABASE_NAME>'
            TABLE_NAME = '<GLUE_TABLE_NAME>'

            # Assuming object key is folder_name/YYYY/MM/DD/HH/sample.json
            partitions_values = source_key.split('/')[5:-1] # Remove the folder name at front and filename at the end
            print(partitions_values) # Output: [‘YYYY’, ‘MM', ‘DD’, ‘HH']
            
            # Initialise the Glue client using Boto 3
            glue_client = boto3.client('glue')

            try:
                # Check if the partition already exists. If yes, skip adding it again
                get_partition_response = glue_client.get_partition(
                    DatabaseName=DATABASE_NAME,
                    TableName=TABLE_NAME,
                    PartitionValues=partitions_values
                )
                print('Glue partition already exists.')

            except Exception as e:
                # Check if the exception is EntityNotFoundException. If yes, go ahead and create parition
                if type(e).__name__ == 'EntityNotFoundException':
                    print('Retrieve Table Details:')
                    get_table_response = glue_client.get_table(
                        DatabaseName=DATABASE_NAME,
                        Name=TABLE_NAME
                    )

                    # Extract the existing storage descriptor and Create custom storage descriptor with new partition location
                    storage_descriptor = get_table_response['Table']['StorageDescriptor']
                    custom_storage_descriptor = copy.deepcopy(storage_descriptor)
                    custom_storage_descriptor['Location'] = storage_descriptor['Location'] + "/".join(partitions_values) + '/'

                    # Create new Glue partition in the Glue Data Catalog
                    create_partition_response = glue_client.create_partition(
                        DatabaseName=DATABASE_NAME,
                        TableName=TABLE_NAME,
                        PartitionInput={
                            'Values': partitions_values,
                            'StorageDescriptor': custom_storage_descriptor
                        }
                    )
                    print('Glue partition created successfully.') 
                else:
                    # Handle exception as per your business requirements
                    print(e)   

        except Exception as e:
            # Handle exception as per your business requirements
            print(e)

import simplejson as json
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

def lambda_handler(event, context): # Lambda handler function, called when the Lambda is triggered by an event
    dynamodb = boto3.resource('dynamodb') # Create a DynamoDB resource
    s3 = boto3.client('s3') # Create an S3 client
    bucket_name = 'secdrive-user-files-nknez' # S3 bucket name
    table = dynamodb.Table('secdrive_users') # Connect to the DynamoDB table

    try:
        print("Before body")
        body = json.loads(event['body'])
        print(body)

        s3.put_object(
            Bucket=bucket_name,
            Key=body['file_name'],
            Body=body['file_content']
        )

        user_id = body['user_id']
        file_name = body['file_name']
        size = body['size']
        path = body['path']
        extension = body['extension']

        response = table.put_item(Item={
            'user_id': user_id,
            'file_name': file_name,
            'size': size,
            'path': path,
            'extension': extension
         })

        print(response)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'message': 'File stored successfully'})
        }
    
    except ClientError as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)}) # Return an error message as JSON
        }
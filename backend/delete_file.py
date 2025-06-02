import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3_client = boto3.client('s3')
    files_table = dynamodb.Table('secdrive_user_files')
    bucket_name = 'secdrive-user-files-nknez'
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        
        # Required fields
        file_id = body.get('file_id')
        user_id = body.get('user_id')
        
        if not file_id or not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'file_id and user_id are required'})
            }
        
        # First, get the file metadata to retrieve the S3 key
        try:
            file_response = files_table.get_item(
                Key={'file_id': file_id}
            )
            
            if 'Item' not in file_response:
                return {
                    'statusCode': 404,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps({'error': 'File not found'})
                }
            
            file_item = file_response['Item']
            
            # Verify the file belongs to the user
            if file_item.get('user_id') != user_id:
                return {
                    'statusCode': 403,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps({'error': 'Unauthorized: File does not belong to user'})
                }
            
            s3_key = file_item.get('s3_key')
            file_name = file_item.get('file_name', 'unknown')
            
        except ClientError as e:
            print(f"Error getting file metadata: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'Failed to retrieve file metadata'})
            }
        
        # Delete the file from S3
        if s3_key:
            try:
                s3_client.delete_object(
                    Bucket=bucket_name,
                    Key=s3_key
                )
                print(f"Successfully deleted S3 object: {s3_key}")
            except ClientError as e:
                print(f"Error deleting S3 object {s3_key}: {str(e)}")
                # Continue with DynamoDB deletion even if S3 deletion fails
                # The file metadata should still be removed
        
        # Delete the file metadata from DynamoDB
        try:
            files_table.delete_item(
                Key={'file_id': file_id}
            )
            print(f"Successfully deleted file metadata for file_id: {file_id}")
        except ClientError as e:
            print(f"Error deleting file metadata: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'Failed to delete file metadata'})
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': f'File "{file_name}" deleted successfully',
                'file_id': file_id,
                's3_key': s3_key
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
    
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': f'Unexpected error: {str(e)}'})
        }

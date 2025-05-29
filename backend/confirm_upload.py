import json
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to store file metadata in DynamoDB after successful S3 upload
    """
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('secdrive_user_files')
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        
        # Required fields
        file_id = body.get('file_id')
        user_id = body.get('user_id')
        file_name = body.get('file_name')
        file_size = body.get('file_size')
        s3_key = body.get('s3_key')
        
        # Optional fields
        content_type = body.get('content_type', 'application/octet-stream')
        file_extension = file_name.split('.')[-1] if '.' in file_name else ''
        
        if not all([file_id, user_id, file_name, file_size, s3_key]):
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({
                    'error': 'file_id, user_id, file_name, file_size, and s3_key are required'
                })
            }
        
        # Create timestamp
        timestamp = datetime.utcnow().isoformat()
        
        # Store file metadata in DynamoDB
        response = table.put_item(
            Item={
                'file_id': file_id,
                'user_id': user_id,
                'file_name': file_name,
                'file_size': int(file_size),
                's3_key': s3_key,
                'content_type': content_type,
                'extension': file_extension,
                'upload_date': timestamp,
                'is_folder': False
            }
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': 'File metadata stored successfully',
                'file_id': file_id
            })
        }
        
    except ClientError as e:
        print(f"DynamoDB ClientError: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': f'Database Error: {str(e)}'})
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

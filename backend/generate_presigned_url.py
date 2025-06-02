import json
import boto3
from botocore.exceptions import ClientError
import uuid
from datetime import datetime

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    bucket_name = 'secdrive-user-files-nknez'
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        user_id = body.get('user_id')
        file_name = body.get('file_name')
        file_size = body.get('file_size')
        content_type = body.get('content_type', 'application/octet-stream')
        
        if not user_id or not file_name:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'user_id and file_name are required'})
            }
        
        # Generate unique file ID and S3 key
        file_id = str(uuid.uuid4())
        s3_key = f"{user_id}/{file_id}_{file_name}"
        
        # Generate pre-signed URL for PUT operation
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': s3_key,
                'ContentType': content_type
            },
            ExpiresIn=3600  # URL expires in 1 hour
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'presigned_url': presigned_url,
                'file_id': file_id,
                's3_key': s3_key,
                'bucket_name': bucket_name
            })
        }
        
    except ClientError as e:
        print(f"AWS ClientError: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': f'AWS Error: {str(e)}'})
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

import json
import boto3
import base64
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to generate data keys for client-side encryption using AWS KMS
    """
    kms_client = boto3.client('kms')
    kms_key_id = 'alias/secdrive-encryption'
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        user_id = body.get('user_id')
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'user_id is required'})
            }
        
        # Generate a data key for client-side encryption
        # The plaintext key will be used client-side, encrypted key stored with metadata
        response = kms_client.generate_data_key(
            KeyId=kms_key_id,
            KeySpec='AES_256',  # 256-bit AES key
            EncryptionContext={
                'user_id': user_id,
                'purpose': 'file_encryption'
            }
        )
        
        # Extract the keys
        plaintext_key = response['Plaintext']
        encrypted_key = response['CiphertextBlob']
        
        # Convert to base64 for transmission
        plaintext_key_b64 = base64.b64encode(plaintext_key).decode('utf-8')
        encrypted_key_b64 = base64.b64encode(encrypted_key).decode('utf-8')
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'plaintext_key': plaintext_key_b64,
                'encrypted_key': encrypted_key_b64,
                'key_id': response['KeyId']
            })
        }
        
    except ClientError as e:
        print(f"KMS ClientError: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': f'KMS Error: {str(e)}'})
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

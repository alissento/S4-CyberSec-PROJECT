import json
import boto3
import base64
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to decrypt data keys for client-side decryption using AWS KMS
    """
    kms_client = boto3.client('kms')
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        user_id = body.get('user_id')
        encrypted_key_b64 = body.get('encrypted_key')
        
        if not user_id or not encrypted_key_b64:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'user_id and encrypted_key are required'})
            }
        
        # Decode the encrypted key from base64
        encrypted_key = base64.b64decode(encrypted_key_b64)
        
        # Decrypt the data key using KMS
        response = kms_client.decrypt(
            CiphertextBlob=encrypted_key,
            EncryptionContext={
                'user_id': user_id,
                'purpose': 'file_encryption'
            }
        )
        
        # Extract the plaintext key
        plaintext_key = response['Plaintext']
        plaintext_key_b64 = base64.b64encode(plaintext_key).decode('utf-8')
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'plaintext_key': plaintext_key_b64,
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

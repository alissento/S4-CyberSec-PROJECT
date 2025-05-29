import simplejson as json
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    files_table = dynamodb.Table('secdrive_user_files')
    s3_client = boto3.client('s3')
    
    try:
        user_id = event['queryStringParameters']['user_id']
        
        # Query user files from DynamoDB
        response = files_table.query(
            IndexName='secdrive_user_id_index',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('user_id').eq(user_id)
        )
        
        files = []
        for item in response['Items']:
            # Generate presigned URL for download
            try:
                download_url = s3_client.generate_presigned_url(
                    'get_object',
                    Params={
                        'Bucket': 'secdrive-user-files-nknez',
                        'Key': item['s3_key']
                    },
                    ExpiresIn=3600  # 1 hour
                )
            except Exception as url_error:
                print(f"Failed to generate download URL for {item['s3_key']}: {url_error}")
                download_url = None
            
            # Format file size
            file_size = int(item['file_size'])
            if file_size < 1024:
                size_str = f"{file_size} B"
            elif file_size < 1024 * 1024:
                size_str = f"{file_size / 1024:.1f} KB"
            elif file_size < 1024 * 1024 * 1024:
                size_str = f"{file_size / (1024 * 1024):.1f} MB"
            else:
                size_str = f"{file_size / (1024 * 1024 * 1024):.1f} GB"
            
            # Format modified date
            try:
                upload_time = datetime.fromisoformat(item['upload_time'].replace('Z', '+00:00'))
                modified_str = upload_time.strftime('%Y-%m-%d %H:%M')
            except:
                modified_str = item.get('upload_time', 'Unknown')
            
            # Determine file type from extension
            file_name = item['file_name']
            file_extension = file_name.split('.')[-1].lower() if '.' in file_name else 'unknown'
            
            files.append({
                'id': item['file_id'],
                'name': file_name,
                'type': file_extension,
                'size': size_str,
                'modified': modified_str,
                'url': download_url,
                'isFolder': False
            })
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'files': files,
                'total_files': len(files)
            })
        }
        
    except ClientError as e:
        print("ClientError:", str(e))
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
        print("Exception:", str(e))
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }
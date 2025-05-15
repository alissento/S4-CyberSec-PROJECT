import simplejson as json
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

def lambda_handler(event, context): # Lambda handler function, called when the Lambda is triggered by an event
    dynamodb = boto3.resource('dynamodb') # Create a DynamoDB resource
    table = dynamodb.Table('secdrive_users') # Connect to the DynamoDB table

    try:
        print("Before body")
        body = json.loads(event['body'])
        print(body)
        operation = event['queryStringParameters']['operation']

        if operation == 'register':
            user_id = body['user_id']
            email = body['email']
            first_name = body['firstName']
            last_name = body['lastName']

            response = table.put_item(Item={
                'user_id': user_id,
                'email': email,
                'first_name': first_name,
                'last_name': last_name
            })

            print(response)
        elif operation == 'update':
            user_id = body['user_id']
            update_expression = "SET " + ", ".join([f"{key} = :{key}" for key in body if key != 'user_id'])
            expression_attribute_values = {f":{key}": value for key, value in body.items() if key != 'user_id'}

            response = table.update_item(
                Key={
                    'user_id': user_id
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_attribute_values
            )

            print(response)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'message': 'User details stored successfully'})
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
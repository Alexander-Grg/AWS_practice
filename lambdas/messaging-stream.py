import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource('dynamodb')
table_name = 'webapp-messages'
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print('event:', event)
    
    message_group_uuid = event['message_group_uuid']
    
    response = table.query(
        KeyConditionExpression=Key('message_group_uuid').eq(message_group_uuid)
    )
    return {
        'statusCode': 200,
        'body': json.dumps(response['Items'])
    }
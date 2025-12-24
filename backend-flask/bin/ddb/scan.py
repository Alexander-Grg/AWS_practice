#!/usr/bin/env python3
# docker-compose exec backend-flask python3 -m bin.ddb.scan
import boto3
import os

attrs = {
  'endpoint_url': os.getenv("AWS_ENDPOINT_URL")
}
dynamodb = boto3.resource('dynamodb',**attrs)
table_name = 'webapp-messages'

table = dynamodb.Table(table_name)
response = table.scan()
items = response['Items']
for item in items:
    print(item)
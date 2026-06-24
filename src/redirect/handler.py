"""GET /{code}, look up a short code and 301-redirect to the original URL."""
import os

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
_table = boto3.resource("dynamodb").Table(TABLE_NAME)


def handler(event, _context):
    code = (event.get("pathParameters") or {}).get("code")
    if not code:
        return {"statusCode": 400, "body": "missing short code"}

    item = _table.get_item(Key={"code": code}).get("Item")
    if not item:
        return {"statusCode": 404, "body": "short code not found"}

    return {"statusCode": 301, "headers": {"location": item["url"]}}

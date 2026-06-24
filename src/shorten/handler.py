"""POST /shorten, store a URL and return a short code."""
import json
import os
import secrets
import string

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
_table = boto3.resource("dynamodb").Table(TABLE_NAME)

_ALPHABET = string.ascii_letters + string.digits
_CODE_LENGTH = 7


def _generate_code(length: int = _CODE_LENGTH) -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(length))


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, _context):
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "request body must be valid JSON"})

    url = payload.get("url")
    if not url or not url.startswith(("http://", "https://")):
        return _response(400, {"error": "a valid 'url' field is required"})

    code = _generate_code()
    _table.put_item(Item={"code": code, "url": url})

    domain = event["requestContext"]["domainName"]
    return _response(201, {"code": code, "short_url": f"https://{domain}/{code}"})

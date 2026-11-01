"""POST /shorten, store a URL and return a short code."""
import json
import os
import secrets
import string
from urllib.parse import urlparse

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
_table = boto3.resource("dynamodb").Table(TABLE_NAME)

_ALPHABET = string.ascii_letters + string.digits
_CODE_LENGTH = 7
_MAX_ATTEMPTS = 5
_MAX_URL_LENGTH = 2048


def _generate_code(length: int = _CODE_LENGTH) -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(length))


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def _is_valid_url(url) -> bool:
    if not isinstance(url, str) or not url or len(url) > _MAX_URL_LENGTH:
        return False
    parsed = urlparse(url)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def _store(url: str):
    """Write the URL under a fresh code; never overwrite an existing one."""
    for _ in range(_MAX_ATTEMPTS):
        code = _generate_code()
        try:
            _table.put_item(
                Item={"code": code, "url": url},
                ConditionExpression="attribute_not_exists(code)",
            )
            return code
        except ClientError as err:
            if err.response["Error"]["Code"] != "ConditionalCheckFailedException":
                raise
    return None


def handler(event, _context):
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "request body must be valid JSON"})

    url = payload.get("url") if isinstance(payload, dict) else None
    if not _is_valid_url(url):
        return _response(400, {"error": "a valid 'url' field is required"})

    code = _store(url)
    if code is None:
        return _response(503, {"error": "could not allocate a unique code, retry"})

    domain = event["requestContext"]["domainName"]
    return _response(201, {"code": code, "short_url": f"https://{domain}/{code}"})

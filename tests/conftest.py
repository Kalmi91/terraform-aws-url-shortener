"""Shared fixtures: a moto-backed DynamoDB table and freshly imported handlers."""
import importlib.util
from pathlib import Path

import boto3
import pytest
from moto import mock_aws

SRC = Path(__file__).resolve().parents[1] / "src"
TABLE_NAME = "url-shortener-test-links"


@pytest.fixture
def table(monkeypatch):
    monkeypatch.setenv("TABLE_NAME", TABLE_NAME)
    monkeypatch.setenv("AWS_DEFAULT_REGION", "eu-central-1")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    with mock_aws():
        ddb = boto3.resource("dynamodb")
        ddb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "code", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "code", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield ddb.Table(TABLE_NAME)


def _load(name):
    # Both handlers are called handler.py, so load each one by file path,
    # after the mock is active, so its module-level table uses moto.
    spec = importlib.util.spec_from_file_location(
        f"{name}_handler", SRC / name / "handler.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def shorten(table):
    return _load("shorten")


@pytest.fixture
def redirect(table):
    return _load("redirect")

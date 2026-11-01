import json

import pytest


def _event(body):
    return {
        "body": body if isinstance(body, str) else json.dumps(body),
        "requestContext": {"domainName": "api.example.test"},
    }


def test_shorten_stores_url_and_returns_short_link(shorten, table):
    resp = shorten.handler(_event({"url": "https://www.hashicorp.com/"}), None)

    assert resp["statusCode"] == 201
    body = json.loads(resp["body"])
    assert len(body["code"]) == 7
    assert body["short_url"] == f"https://api.example.test/{body['code']}"
    assert table.get_item(Key={"code": body["code"]})["Item"]["url"] == (
        "https://www.hashicorp.com/"
    )


def test_shorten_retries_on_code_collision(shorten, table, monkeypatch):
    table.put_item(Item={"code": "taken00", "url": "https://old.example/"})
    codes = iter(["taken00", "taken00", "fresh00"])
    monkeypatch.setattr(shorten, "_generate_code", lambda: next(codes))

    resp = shorten.handler(_event({"url": "https://new.example/"}), None)

    assert resp["statusCode"] == 201
    assert json.loads(resp["body"])["code"] == "fresh00"
    # The pre-existing link must not have been overwritten.
    assert table.get_item(Key={"code": "taken00"})["Item"]["url"] == "https://old.example/"


def test_shorten_gives_up_when_every_code_collides(shorten, table, monkeypatch):
    table.put_item(Item={"code": "taken00", "url": "https://old.example/"})
    monkeypatch.setattr(shorten, "_generate_code", lambda: "taken00")

    resp = shorten.handler(_event({"url": "https://new.example/"}), None)

    assert resp["statusCode"] == 503
    assert table.get_item(Key={"code": "taken00"})["Item"]["url"] == "https://old.example/"


@pytest.mark.parametrize(
    "body",
    [
        {"url": "not-a-url"},
        {"url": "ftp://example.com/file"},
        {"url": "https://"},
        {"url": ""},
        {"url": 42},
        {"url": "https://example.com/" + "a" * 2048},
        {},
        ["https://example.com/"],
    ],
)
def test_shorten_rejects_bad_url(shorten, body):
    resp = shorten.handler(_event(body), None)

    assert resp["statusCode"] == 400


def test_shorten_rejects_invalid_json(shorten):
    resp = shorten.handler(_event("{not json"), None)

    assert resp["statusCode"] == 400

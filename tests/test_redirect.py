def _event(code):
    return {"pathParameters": {"code": code}} if code is not None else {}


def test_redirect_returns_301_to_stored_url(redirect, table):
    table.put_item(Item={"code": "abc1234", "url": "https://www.hashicorp.com/"})

    resp = redirect.handler(_event("abc1234"), None)

    assert resp["statusCode"] == 301
    assert resp["headers"]["location"] == "https://www.hashicorp.com/"


def test_redirect_unknown_code_is_404(redirect):
    resp = redirect.handler(_event("nope000"), None)

    assert resp["statusCode"] == 404


def test_redirect_missing_code_is_400(redirect):
    resp = redirect.handler(_event(None), None)

    assert resp["statusCode"] == 400

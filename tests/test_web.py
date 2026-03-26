import json
from web import app


def get_client():
    """Create a Flask test client."""
    app.config["TESTING"] = True
    return app.test_client()


def test_health_status_code():
    """GET /health returns HTTP 200."""
    client = get_client()
    response = client.get("/health")
    assert response.status_code == 200


def test_health_content_type():
    """GET /health returns JSON content type."""
    client = get_client()
    response = client.get("/health")
    assert response.content_type == "application/json"


def test_health_body():
    """GET /health returns {"status": "ok"} body."""
    client = get_client()
    response = client.get("/health")
    data = json.loads(response.data)
    assert data["status"] == "ok"


def test_index_still_works():
    """GET / still returns HTTP 200 (existing route not broken)."""
    client = get_client()
    response = client.get("/")
    assert response.status_code == 200

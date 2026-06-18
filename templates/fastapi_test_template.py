"""Token-minimal FastAPI check — runs in-process, no server, no browser.

Copy next to your app, point the import at your FastAPI instance, and run:
    pytest tests/test_<feature>.py -q
Output is a one-line pytest summary the agent can read for ~10 tokens.
"""
from fastapi.testclient import TestClient

from app.main import app  # <-- your FastAPI() instance

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200, r.text


def test_create_invoice():
    r = client.post("/invoices", json={"client_id": 1, "amount_cents": 5000})
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["amount_cents"] == 5000
    assert "id" in body

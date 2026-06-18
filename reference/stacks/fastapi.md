# FastAPI — in-process verification (no server, no browser)

FastAPI's `TestClient` (Starlette/HTTPX) drives the app **in-process**: no TCP socket, no
running server, no network. Plain `assert`s → a one-line pytest summary. This is the cheapest
possible verification for an HTTP API.

## Setup

```python
# tests/test_clients.py
from fastapi.testclient import TestClient
from app.main import app          # your FastAPI() instance

client = TestClient(app)

def test_list_clients():
    r = client.get("/clients")
    assert r.status_code == 200, r.text
    assert len(r.json()) >= 1
```

Run:
```bash
pytest tests/test_clients.py -q        # → "1 passed in 0.04s"
```

## Map line

```
list-clients | pytest tests/test_clients.py -q | passed
```

## Notes

- Assert on the **effect**, not just the status: check the body, the created row, the changed
  field. A 200 alone is a weak check.
- `-q` keeps output to a one-line summary. On failure, pytest prints the single failing assert
  — that's the line `verify.sh` surfaces.
- For DB-backed endpoints, combine with deterministic fixtures (see `supabase.md`) or a
  transactional test DB so each run starts from a known state.
- No browser, ever, for API logic. The browser cannot tell you more than the assert can here.

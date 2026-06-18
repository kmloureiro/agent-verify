# Verification Map

One line per feature. Keep it short — the agent reads this to verify cheaply.
Format: `feature | command | pass-signal`
- `pass-signal` is optional text that must appear in stdout to PASS.
- If omitted, exit code 0 = PASS.

<!-- examples — replace with your real features -->
health        | curl -sf localhost:8000/health           | ok
list-clients  | pytest tests/test_clients.py -q           | passed
create-invoice| pytest tests/test_invoice.py::test_create -q | 1 passed
db-rls        | supabase test db                          | ok

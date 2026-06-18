# Anti-patterns (what makes this fail)

## Flaky checks
A check that passes/fails on timing, ordering, network, or wall-clock is worse than no check:
it forces re-runs (tokens) and teaches the agent to distrust PASS.
- Use deterministic fixtures (fixed IDs, seeded data).
- No `sleep`-and-hope. Poll a condition with a bounded timeout, or use in-process clients.
- Freeze time and randomness where they matter.

## False PASS
A check that can't actually fail is a lie that costs you later.
- Assert on the *effect*, not that the call returned. `assert r.status_code == 201` AND assert
  the row exists / the field changed.
- Write the check so it fails first (break the feature mentally): would this catch it?
- Avoid `assert True`, empty `try/except`, and asserting on mocks you control end-to-end.

## Over-engineering
This skill is a scalpel, not a test pyramid.
- One feature → one fast check. Resist adding a suite per feature.
- Don't introduce a new framework. Use the runner already in the repo.
- Don't build fixtures factories, custom DSLs, or a config system for v1. A shell script and a
  flat map file are enough.

## Browser creep
The failure mode this skill exists to prevent.
- Don't verify logic, data, or API contracts through the browser.
- Don't pull DOM/screenshots into the model's context to "see what happened" — read the assert.
- Browser is level 4, last, end-only, verdict-only.

## Map rot
`VERIFICATION_MAP.md` is the contract. Keep it honest.
- Every feature line must point at a command that exists and runs.
- Remove checks for deleted features.
- Keep it short. Long maps degrade agent performance (see patterns.md).

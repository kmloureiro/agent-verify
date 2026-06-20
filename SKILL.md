---
name: agent-verify
description: This skill should be used when building or changing a feature in an app, API, or site and you want to verify it works WITHOUT burning tokens on browser automation, screenshots, or DOM dumps. Use it to generate a token-minimal CLI verification harness alongside each feature, run checks in a sandbox, and surface only PASS/FAIL + the failing line. Triggers on "verify this works", "test this feature", "did the change break anything", "check the endpoint", "add tests", or any agent self-verification loop. Browser/visual checks are the fallback of last resort, only for genuinely visual UI, and only at the end.
version: 1.1.0
---

# agent-verify

Make the thing you build verifiable by the cheapest mechanism that can falsify it. Verify via CLI by default. The model should read ~20 tokens (`PASS` / `FAIL: line`), never a DOM dump or a screenshot.

## The one rule

> Use the lightest mechanism that can prove a feature wrong. Escalate only when it can't.

```
in-process assert  →  CLI / curl + exit code  →  DB test (TAP)  →  headless browser (visual only, last)
   cheapest                                                            most expensive
```

90% of what agents build (logic, data, API contracts, flows) is verifiable with zero browser. Reserve the browser for pixels.

## Loop (per feature)

1. **Detect once.** Run `scripts/detect-stack.sh`. It prints the test runner and stack in a few lines. Don't impose a new framework — use what's there.
2. **Build the feature.**
3. **Write ONE token-minimal check** using the stack's in-process / CLI primitive (see `reference/stacks/`). The check must print `PASS` or a single `FAIL:` line — never dumps.
4. **Append one line to `VERIFICATION_MAP.md`**: `feature | command | pass-signal`. This is the contract the agent reads next time.
5. **Run `scripts/verify.sh [feature]`** and read only the result. Edit → verify → repeat on the result, not on logs.

## What NOT to do

- Don't reach for Playwright/the browser to check logic, data, or API responses. That's the token leak this skill exists to stop.
- Don't prescribe a TDD ritual. Surface *which* check proves *this* feature, not a procedure. (Procedure without targeted context measurably backfires — see `reference/patterns.md`.)
- Don't return raw output to the context. Filter in the sandbox, surface the result. (`console.log(result)`, not the 10k rows.)
- Don't let checks grow. One feature, one fast deterministic check. Keep `VERIFICATION_MAP.md` short — short maps outperform long ones.

## Output contract (always)

```
PASS auth-login
FAIL create-invoice: expected 201, got 500
```

Exit `0` = all pass. Non-zero = something failed. That is all the model needs.

## When the browser IS unavoidable

Only for genuinely visual UI (layout, styling, visual regression) and only at the very end. Even then: one headless run, return a PASS/FAIL or a diff verdict — never a full screenshot or DOM into the context. See `reference/stacks/nextjs.md`.

## Files

- `scripts/detect-stack.sh` — prints stack + runner, token-minimal.
- `scripts/verify.sh` — runs mapped checks, emits only PASS/FAIL + failing line.
- `VERIFICATION_MAP.md` — the short feature→command map (the agent maintains it).
- `reference/stacks/` — copy-paste recipes: FastAPI (in-process TestClient), Supabase (seed + reset + pgTAP), Next.js (route handlers + last-resort visual), SvelteKit (load/actions/+server + RLS rolled back, Playwright CLI last).
- `reference/patterns.md` — token-minimal verification patterns + the evidence behind them.
- `reference/anti-patterns.md` — flaky tests, false PASS, over-engineering guards.
- `templates/` — starting points for the map, a FastAPI test, a Supabase seed.

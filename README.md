# agent-verify

**A token-minimal verification harness for AI coding agents.** When an agent builds a feature,
it generates a CLI check alongside it that returns `PASS` / `FAIL: line` — instead of driving a
browser and pulling DOM dumps and screenshots into the context window.

Verify by the cheapest mechanism that can prove a feature wrong. Read ~20 tokens, not ~20,000.

---

## The problem

Coding agents waste a large share of their tokens *verifying their own work*. Driving a browser
through an MCP server returns the page DOM, console logs, and screenshots into the model's
context — thousands to tens of thousands of tokens **per check**. Most of what agents build
(logic, data, API contracts, flows) never needed a browser to verify in the first place.

Independent benchmarks have measured browser-MCP verification at **~114k tokens per test**
versus **~27k** for a CLI approach. Anthropic's own "code execution with MCP" guidance shows
filtering inside the sandbox and returning only the result taking a scenario from **150k → 2k
tokens (~98.7%)**. The direction is consistent and large.

## The idea

> Build the check **with** the feature. Run it in the sandbox. Surface only the verdict.

```
in-process assert  →  CLI / curl + exit code  →  DB test (TAP)  →  headless browser (visual only, last)
   cheapest                                                            most expensive
```

The agent keeps a short `VERIFICATION_MAP.md` (`feature | command | pass-signal`) and verifies
with one script that prints only:

```
PASS auth-login
FAIL create-invoice: expected 201, got 500
```

Exit `0` = all good. That's everything the model needs to decide its next move.

## Why it works (the research)

- **Context beats procedure.** A study (TDAD, arXiv 2603.17973) found a short test-context map
  cut regressions ~70%, while a TDD *procedure without* that context made them **worse than no
  intervention**. Shrinking the instruction file 107 → 20 lines quadrupled task resolution.
  → so this skill ships a *short map*, not a playbook.
- **Filter in the sandbox.** Return only what you log; intermediate data never enters context
  (Anthropic).
- **Harness-first.** Review the harness output (what passed), not the diff (Datadog).

See [`reference/patterns.md`](reference/patterns.md) for the evidence and sources.

## Install (Claude Code skill)

```bash
git clone https://github.com/kmloureiro/agent-verify ~/.claude/skills/agent-verify
```

It also works as a plain repo any agent can read — point your agent at `SKILL.md`.

## Use

1. `bash scripts/detect-stack.sh` — prints your stack + test runner (a few lines).
2. Build a feature.
3. Add one token-minimal check using your stack's primitive
   ([FastAPI](reference/stacks/fastapi.md) · [Supabase](reference/stacks/supabase.md) ·
   [Next.js](reference/stacks/nextjs.md)).
4. Append one line to `VERIFICATION_MAP.md`.
5. `bash scripts/verify.sh [feature]` — read only `PASS`/`FAIL`.

Browser checks are the fallback of last resort — visual UI only, at the end, verdict-only.

## What it is NOT

- Not a test framework. It uses the runner you already have (pytest, vitest, jest, go test, pgTAP).
- Not a replacement for visual testing. It's the 90% you shouldn't be paying browser prices for.
- Not a TDD ritual. One feature, one fast deterministic check, one line in the map.

## Stacks with recipes in v1

FastAPI (in-process `TestClient`) · Supabase (seed + `db reset` + pgTAP) · Next.js (route
handlers; visual as last resort). The pattern generalizes to any language with a CLI test runner.

## License

MIT — see [LICENSE](LICENSE). Contributions and new stack recipes welcome.

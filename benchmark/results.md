# Benchmark: browser verification vs CLI verification

**The headline:** verifying a feature by pulling a browser snapshot (and a screenshot) into the
agent's context costs **~260x more tokens** than a CLI `PASS`/`FAIL` — and that's measured on a
*small* page. Real app flows are bigger and multi-step.

## Measured run (reproducible)

- **Target:** `https://gyrls.app/` landing page (public, Next.js + Supabase, live on Vercel)
- **Date:** 2026-06-18
- **Browser snapshot:** captured once via Playwright MCP `browser_snapshot` → 5,993 bytes of
  accessibility tree.
- **Tooling:** `measure_tokens.py` (chars/3.6 heuristic; install `tiktoken` for BPE counts).

| Mode | Tokens (est.) |
|------|---------------|
| CLI verification (`PASS landing-loads` + 1 more line) | **11** |
| Browser DOM snapshot (1 page) | 1,648 |
| + one 1280×720 screenshot | 1,229 |
| **Browser total (snapshot + screenshot)** | **2,877** |
| **Ratio** | **~262×** |
| **Saved per verification** | **~2,866 tokens** |

Reproduce:
```bash
# 1. capture a snapshot of any live page via your browser MCP, save to a .yml/.txt file
# 2.
python3 benchmark/measure_tokens.py compare sample-cli-output.txt sample-browser-snapshot.yml 1280x720
```

## Why this is conservative

- The landing page is small and static. **Logged-in app pages** (lists, tables, feeds) produce
  much larger accessibility trees — often 5–20k+ tokens per snapshot.
- A real verification is rarely one snapshot. The agent navigates, clicks, re-snapshots — each
  step re-injects the DOM. **Multi-step flows multiply the cost.**
- Independent third-party benchmarks have reported Playwright-MCP test runs at **~114k tokens**
  vs **~27k** for a CLI approach (per test), consistent with this direction at larger scale.
- Anthropic's "code execution with MCP" shows filtering in-sandbox taking a scenario from
  **150k → 2k tokens (~98.7%)**.

## What this does NOT claim

- Token estimates are ±~15% (Claude has no public tokenizer; this uses a documented heuristic).
  The **ratio** is the robust signal, not the absolute count.
- The browser is sometimes irreducible (visual regression, layout). This benchmark is the case
  *for* CLI-first on the 90% that never needed a browser — not *against* visual testing.
- One target, one run. Run it on your own app/feature for a number that fits your stack.

## Take it further

Measure a real authenticated flow in your app: capture the snapshot(s) a browser-MCP
verification would produce for one feature, run `measure_tokens.py compare` against the
agent-verify CLI check for the same feature, and publish your ratio.

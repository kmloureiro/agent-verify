# Verification patterns (token-minimal)

The goal is always the same: prove a feature wrong with the fewest tokens entering the
model's context. Pick the cheapest pattern that can falsify the feature.

## The escalation ladder

| Level | Mechanism | Cost | Use for |
|------|-----------|------|---------|
| 1 | In-process assert (TestClient, unit) | cheapest | logic, request/response, validation |
| 2 | CLI / `curl` + exit code | cheap | running endpoints, scripts, integrations |
| 3 | DB test (pgTAP → TAP text) | cheap | RLS, constraints, triggers, data shape |
| 4 | Headless browser, return verdict only | expensive | genuinely visual UI, **last resort, end only** |

Start at the lowest level that applies. Only climb when the level below genuinely can't
prove the thing.

## Make output token-minimal

- **Filter in the sandbox, surface the result.** Don't return 10k rows; compute the answer
  and print one line. (`console.log(rows.length)`, not `console.log(rows)`.)
- **One line per failure.** `FAIL feature: expected 201, got 500`. No tracebacks into context
  unless a check actually fails and you need the one relevant line.
- **Exit codes carry the verdict.** `0` = pass. The agent reads the code, not the logs.
- **Deterministic fixtures.** Same seed → same result. Flaky checks cost more than no checks
  because they force re-runs and erode trust in PASS.

## Context, not procedure

Surface *which* check proves *this* feature (a short map: feature → command). Do **not** hand
the agent a TDD procedure to follow.

> Evidence: a study (TDAD, arXiv 2603.17973) found that delivering a short test-context map
> cut regressions ~70%, while giving the same agents a TDD *procedure without that context*
> made regressions **worse than no intervention** (9.94% vs 6.08% baseline). Shrinking the
> instruction file from 107 → 20 lines alone quadrupled task resolution (12% → 50%).
> Lesson: keep `VERIFICATION_MAP.md` short and concrete. Maps beat playbooks.

## Why this saves tokens

- Anthropic ("Code execution with MCP"): filtering results inside the execution environment
  and returning only what's logged took one scenario from 150k → 2k tokens (~98.7%).
- Independent benchmarks of Playwright MCP vs a CLI approach report per-test costs dropping
  from ~114k tokens to ~27k by keeping DOM/screenshots out of the context.

Numbers are illustrative, not a universal benchmark — but the direction is consistent and
large. Measure your own delta once and you have the headline for your repo.

## When the browser is unavoidable

Layout, styling, visual regression, client-only interactivity. Even then:
- Run headless, once, at the end.
- Return a **verdict** (PASS/FAIL or a diff summary), never a screenshot or DOM into context.
- Persist artifacts to disk; let the human open them, not the model.

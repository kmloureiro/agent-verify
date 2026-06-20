# SvelteKit + Supabase — cheap checks first, browser last

A SvelteKit app is mostly server functions and HTTP: `load`, form `actions`, and `+server.ts`
endpoints are plain functions you can call or `curl` without a browser. Data and access rules live
in Postgres, so verify those at the DB layer. Reserve the browser for flows that only exist after
hydration — the most expensive rung, and the one this stack tempts you to overuse.

```
pure logic (vitest)  →  endpoint / load / action  →  DB + RLS (SQL, rolled back)  →  browser e2e (Playwright CLI, last)
   cheapest                                                                              most expensive
```

## Level 1 — pure logic (vitest, no browser, ms)

Move decision logic (state machines, formatting, validation) out of `.svelte` components into
plain `.ts` modules, then unit-test the module. Components stay thin; the logic verifies in ms.

```ts
// src/lib/states.ts
export const isOverdue = (dueISO: string | null, done: boolean) =>
  !!dueISO && !done && new Date(dueISO) < new Date();

// src/lib/states.test.ts
import { expect, test } from 'vitest';
import { isOverdue } from './states';
test('overdue only when open and past due', () => {
  expect(isOverdue('2020-01-01', false)).toBe(true);
  expect(isOverdue('2020-01-01', true)).toBe(false);
});
```

A standalone Vitest config — `environment: 'node'`, `include: ['src/**/*.test.ts']`, no
`sveltekit()` plugin — is enough here: pure modules don't import `$app`/`$env`, and the scope keeps
Vitest off the Playwright specs under `tests/`. Run `vitest run --reporter=dot`. (Component tests
that import `$app` are a separate rail: SvelteKit plugin + `environment: 'jsdom'`.)

## Level 2 — endpoints, load & actions (no browser)

A `+server.ts` handler is just `(RequestEvent) => Response`. The cheapest check is `curl` against
`vite dev` (port 5173); assert on the effect, not only the status:

```bash
curl -sf localhost:5173/api/clients | jq -e 'length > 0' >/dev/null && echo PASS || echo FAIL
```

For `load`/actions with real logic, extract that logic into a `.ts` helper and unit-test it at
Level 1, keeping the wrapper thin. Booting the framework to test a function it could have called
directly is wasted cost.

## Level 3 — DB / RLS / writes (no browser)

Keep e2e read-only (next level) and verify every write here, where you can roll back.
[`supabase.md`](supabase.md) covers the pgTAP path; without pgTAP, a pragmatic equivalent is a
plpgsql `do $$ … $$` block that `raise`s on a failed assertion, wrapped in `begin … rollback` —
deterministic, zero residue. Simulate the calling user so RLS runs as them, not as a superuser
(`auth.uid()` reads `sub`; set `role` in the claims too, for policies keyed on it):

```sql
-- supabase/tests/rls.test.sql
begin;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"role":"authenticated","sub":"00000000-0000-0000-0000-000000000001"}', true);

do $$
declare n int;
begin
  select count(*) into n from invoices where status = 'paid';
  if n <> 1 then raise exception 'expected 1 paid invoice, got %', n; end if;
end $$;
rollback;
```

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls.test.sql
```

No exception = PASS; the first `raise` is the failing line. `ON_ERROR_STOP=1` is required —
without it psql swallows the error and exits `0`.

## Level 4 — browser e2e (Playwright CLI) — last resort

Use the **Playwright CLI** (`playwright test`), not a browser MCP: an MCP pulls DOM + screenshots
into context every step; the CLI returns one line and an exit code. This repo's own benchmark
measured a **~260×** token gap — see [`../patterns.md`](../patterns.md). Keep e2e read-only; writes
belong to Level 3.

**Authenticate once, reuse the session** — for speed and isolation (one login, not one per test;
specs don't fight over auth state; per-test login can also flake under load). Use a dev-only login
route that 404s in production, then **assert login succeeded before saving `storageState`** (saving
an unauthenticated state makes every dependent spec fail confusingly):

```ts
// src/routes/auth/qa-login/+server.ts — dev-only, 404 in prod
import { dev } from '$app/environment';
import { error, redirect } from '@sveltejs/kit';
export const GET = async ({ locals }) => {
  if (!dev) throw error(404);
  await locals.supabase.auth.signInWithPassword({
    email: process.env.QA_USER_EMAIL!, password: process.env.QA_USER_PASSWORD!
  });
  throw redirect(303, '/');
};

// tests/auth.setup.ts
setup('authenticate once', async ({ page }) => {
  await page.goto('/auth/qa-login');
  await expect(page.getByTestId('user-menu')).toBeVisible();   // login worked
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

Wire a `setup` project (`testMatch /auth\.setup\.ts/`) as a `dependencies` of the chromium project,
with `use.storageState` pointing at the saved file.

**Hydration race.** The first click can land before the app hydrates and silently no-op. Make the
action idempotent so it retries until it takes, and **bound it** (`toPass` defaults to no timeout):

```ts
await expect(async () => {
  await page.getByRole('button', { name: 'Add' }).click();
  await expect(page.getByText('Added')).toBeVisible();
}).toPass({ timeout: 10_000 });
```

Never wrap a **toggle** this way (a re-click undoes the first); for a toggle, assert an
already-hydrated marker first, then click once. Run `npx playwright test --reporter=line`. Visual
regression sits even lower: a one-shot gate returning a diff verdict, never a screenshot.

## Notes — SvelteKit + supabase-js gotchas

- **Dev-only SSR `fetch` warning.** In dev, SvelteKit swaps `globalThis.fetch` for an instrumented
  wrapper during each render window. Under concurrent SSR (parallel e2e), a supabase-js call from
  one request can fall into another's wrapper and trip a warning about calling `fetch` eagerly
  during SSR (exact wording varies by version). Hand supabase-js a **stable native fetch** captured
  at module load, so its calls never enter the per-render window (inert in production):

  ```ts
  // hooks.server.ts
  const baseFetch = globalThis.fetch.bind(globalThis);   // captured once, before any render
  event.locals.supabase = createServerClient(URL, KEY, { cookies: { /* … */ }, global: { fetch: baseFetch } });
  ```

  Passing `event.fetch` does **not** fix it — that still routes through the instrumented fetch.
- **`Response.text()` strips the BOM.** To assert a CSV starts with a UTF-8 BOM, check raw bytes
  (`await res.arrayBuffer()`), not the decoded string.
- **`Intl` currency whitespace.** Don't assert exact spacing before the symbol: pt-PT uses a
  no-break space (U+00A0), some locales a narrow one (U+202F), never a plain space. Normalize
  whitespace, or assert the number, not the formatted string.
- **`verify.sh` splits the map on `|`.** Keep shell pipes out of map commands — put a piped check in
  a one-line script and reference that, or rely on a runner's exit code.

## Map lines

```
states-logic | vitest run --reporter=dot states
db-rls       | psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls.test.sql
e2e-flows    | npx playwright test --reporter=line
```

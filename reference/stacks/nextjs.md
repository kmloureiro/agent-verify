# Next.js — cheap checks first, visual last

Most of a Next.js app is verifiable without a browser. Route handlers, server actions, and data
logic are just functions and HTTP. Reserve the browser for what is genuinely visual.

## Level 1 — route handlers / API routes (no browser)

Test the handler as a function or hit it with `fetch` against `next dev`/`next start`:

```ts
// tests/clients.test.ts  (vitest)
import { GET } from "@/app/api/clients/route";

it("lists clients", async () => {
  const res = await GET(new Request("http://localhost/api/clients"));
  expect(res.status).toBe(200);
  const body = await res.json();
  expect(body.length).toBeGreaterThan(0);
});
```

```bash
vitest run --reporter=dot     # → one-line dot summary
```

Or against a running dev server, token-minimal:
```bash
curl -sf localhost:3000/api/clients | jq -e 'length > 0' >/dev/null && echo PASS || echo FAIL
```

## Level 2 — server actions / data functions

Import and call them directly in a vitest/jest test with seeded data. No browser needed to
verify that a mutation wrote the right row — assert on the DB (see `supabase.md`).

## Level 4 — visual, LAST resort, end only

Only for layout, styling, or visual regression. Run headless **once**, return a **verdict**,
never a screenshot/DOM into the model's context:

```bash
# example: playwright assertion that EXITS with a code, prints one line
npx playwright test visual.spec.ts --reporter=line   # → "1 passed" / "1 failed"
```

If you capture a screenshot for visual regression, diff it on disk and surface only the
verdict (`PASS` / `pixels changed: 0.4%`). The human opens the image, not the model.

## Map lines

```
api-clients   | curl -sf localhost:3000/api/clients | jq -e 'length>0' | true
ui-checkout   | npx playwright test checkout.spec.ts --reporter=line | passed
```

> Keep the `ui-*` lines few. They are the expensive ones. If a check can move down the ladder
> to a route-handler test, move it.

# Supabase — deterministic fixtures + DB tests (TAP text)

The Supabase CLI already gives you the three primitives this skill needs: deterministic seed,
one-command reset, and a native DB test runner that emits plain TAP text (no browser).

## Deterministic fixtures

`supabase/seed.sql` is auto-detected (config default `db.seed.enabled = true`). It runs on the
first `supabase start` and on every `supabase db reset`, **after** migrations. Use fixed IDs so
checks can assert on known rows. See `templates/supabase_seed_template.sql`.

## Restore known state (one command)

```bash
supabase db reset      # recreates local Postgres, applies migrations, re-seeds
```

Anything not in migrations or seed is discarded — that's the point. Every check starts clean.

## DB tests → TAP

Write pgTAP tests under `supabase/tests/`, then:

```bash
supabase test db       # runs pg_prove, prints TAP: "ok 1 - ...", "not ok 2 - ..."
```

Each test runs in its own transaction and is rolled back regardless of result, so tests don't
leak state into each other.

Example (`supabase/tests/rls.test.sql`):
```sql
begin;
select plan(1);
select is(
  (select count(*) from invoices where status = 'paid'),
  1::bigint,
  'one paid invoice in seed'
);
select * from finish();
rollback;
```

## Map lines

```
db-reset | supabase db reset            | Finished
db-rls   | supabase test db             | ok
```

## Notes

- TAP output is text and tiny — `verify.sh` matches `ok` / surfaces the first `not ok` line.
- Transaction rollback means pgTAP tests can't persist state for later inspection; assert
  within the test.
- CLI v2 gates seeding on a `[db.seed]` block (written by `supabase init`). Legacy repos or
  `--no-seed` skip it — check `detect-stack.sh` output.

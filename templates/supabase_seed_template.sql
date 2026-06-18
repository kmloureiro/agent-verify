-- supabase/seed.sql — deterministic fixtures.
-- Auto-loaded on `supabase start` and re-applied on every `supabase db reset`,
-- AFTER migrations run. Keep it small and deterministic: same seed → same checks.
-- Fixed IDs so checks can assert on known rows.

insert into public.clients (id, name, email) values
  (1, 'Acme Lda',  'acme@example.com'),
  (2, 'Globex SA', 'globex@example.com')
on conflict (id) do nothing;

insert into public.invoices (id, client_id, amount_cents, status) values
  (1, 1, 5000, 'paid'),
  (2, 2, 12000, 'pending')
on conflict (id) do nothing;

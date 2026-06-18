# Example: the harness verifying itself

This folder is a self-contained smoke test of `verify.sh`, using only shell (no deps), so you
can confirm the harness works on any machine:

```bash
cd examples
bash ../scripts/verify.sh
```

Expected output:

```
PASS echoes-ok
PASS exit-zero
FAIL always-fails: nope
```

(`always-fails` is intentional — it demonstrates the one-line failure surface.)
Exit code is non-zero because one check fails by design. Delete that line to see a clean run.

The real value is on a real stack: see the recipes in
[`../reference/stacks/`](../reference/stacks/).

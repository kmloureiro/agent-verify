#!/usr/bin/env bash
# detect-stack.sh — token-minimal stack/runner detection.
# Prints a few lines. No dumps. Meant to be read by an agent.
set -euo pipefail
root="${1:-.}"
cd "$root"

found=0
say() { echo "$1"; found=1; }

# --- Python ---
if [ -f pyproject.toml ] || [ -f requirements.txt ] || ls ./*.py >/dev/null 2>&1; then
  if grep -rqs "fastapi" pyproject.toml requirements.txt 2>/dev/null; then
    say "python: fastapi (use in-process TestClient — reference/stacks/fastapi.md)"
  fi
  if command -v pytest >/dev/null 2>&1 || grep -rqs "pytest" pyproject.toml requirements.txt 2>/dev/null; then
    say "runner: pytest -q"
  fi
fi

# --- Node / JS ---
if [ -f package.json ]; then
  if grep -qs '"next"' package.json; then say "node: next.js (route handlers cheap; visual = last resort — reference/stacks/nextjs.md)"; fi
  if grep -qs '"vitest"' package.json; then say "runner: vitest run --reporter=dot"; fi
  if grep -qs '"jest"' package.json;   then say "runner: jest --silent"; fi
  if grep -qs '"playwright"' package.json; then say "browser: playwright present (visual only, end only)"; fi
fi

# --- Go ---
if [ -f go.mod ]; then say "go: module"; say "runner: go test ./... -count=1"; fi

# --- Supabase ---
if [ -d supabase ]; then
  say "supabase: present (seed=supabase/seed.sql, reset='supabase db reset', tests='supabase test db' → TAP — reference/stacks/supabase.md)"
fi

# --- Existing harness ---
[ -f VERIFICATION_MAP.md ] && say "map: VERIFICATION_MAP.md exists (read it before adding checks)"

[ "$found" -eq 0 ] && echo "stack: unknown — pick the cheapest CLI check the language allows; avoid the browser."
exit 0

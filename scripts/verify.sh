#!/usr/bin/env bash
# verify.sh — run mapped checks, emit ONLY PASS/FAIL + the failing line.
# Reads VERIFICATION_MAP.md. Format per line:  feature | command | pass-signal
#   - pass-signal optional. If given, command stdout must contain it to PASS.
#   - if omitted, exit code 0 = PASS.
# Usage:
#   verify.sh                 # run every mapped feature
#   verify.sh <feature>       # run one feature (substring match on name)
set -uo pipefail

map="${MAP_FILE:-VERIFICATION_MAP.md}"
filter="${1:-}"

[ -f "$map" ] || { echo "FAIL: no $map (run detect-stack.sh, then add checks)"; exit 2; }

fails=0
ran=0

while IFS= read -r line; do
  # skip blanks, comments, markdown headings/tables
  case "$line" in ''|\#*|'|'*|'---'*) continue;; esac
  echo "$line" | grep -q '|' || continue

  feature="$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); print $1}')"
  command="$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')"
  signal="$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}')"
  [ -z "$feature" ] || [ -z "$command" ] && continue
  [ -n "$filter" ] && [ "${feature#*"$filter"}" = "$feature" ] && continue

  ran=$((ran+1))
  out="$(eval "$command" 2>&1)"; code=$?

  ok=1
  [ "$code" -ne 0 ] && ok=0
  [ -n "$signal" ] && { echo "$out" | grep -qF "$signal" || ok=0; }

  if [ "$ok" -eq 1 ]; then
    echo "PASS $feature"
  else
    fails=$((fails+1))
    reason="$(echo "$out" | grep -iE 'error|assert|expected|fail|traceback|✗|not ok' | head -1)"
    [ -z "$reason" ] && reason="$(echo "$out" | tail -1)"
    echo "FAIL $feature: ${reason:-exit $code}"
  fi
done < "$map"

[ "$ran" -eq 0 ] && { echo "FAIL: no checks matched '${filter}'"; exit 2; }
[ "$fails" -gt 0 ] && exit 1
exit 0

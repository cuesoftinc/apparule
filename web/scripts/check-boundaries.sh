#!/usr/bin/env bash
# Legacy quarantine gate (web-implementation.md §1 / §8): live paths carry
# zero dead code — nothing outside src/legacy may import from src/legacy.
# CI-runnable via `npm run check:boundaries` (wired into `npm test`).
set -uo pipefail

cd "$(dirname "$0")/.."

# Catches `from "…legacy…"`, bare `import "…legacy…"`, and require()/import().
matches=$(grep -rn \
  --include='*.ts' --include='*.tsx' \
  --exclude-dir=legacy \
  -E "(from |import |import\(|require\()[[:space:]]*['\"]([^'\"]*/)?legacy(/[^'\"]*)?['\"]" \
  src || true)

if [ -n "$matches" ]; then
  echo "✗ boundary violation: src/legacy is quarantined — live paths must not import legacy code:" >&2
  echo "$matches" >&2
  exit 1
fi

echo "✓ boundaries ok — no legacy imports outside src/legacy"

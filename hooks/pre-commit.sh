#!/bin/bash
# Pre-Commit Hook - Smart, contextual validation
# Only runs checks relevant to what's being committed

set -e

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

# === Categorize Changes ===
HAS_TS=false
HAS_API=false
HAS_DB=false
HAS_AUTH=false
HAS_TEST=false
HAS_CONFIG=false
HAS_DEPS=false

for file in $STAGED_FILES; do
  case "$file" in
    *.ts|*.tsx) HAS_TS=true ;;
    *.test.*|*.spec.*|__tests__/*) HAS_TEST=true ;;
    package.json|package-lock.json|pnpm-lock.yaml) HAS_DEPS=true ;;
    *.config.*|next.config.*|tailwind.config.*) HAS_CONFIG=true ;;
  esac

  # Check file content patterns
  if [[ "$file" == *"api/"* ]] || [[ "$file" == *"actions"* ]] || [[ "$file" == *"route.ts"* ]]; then
    HAS_API=true
  fi
  if [[ "$file" == *"schema"* ]] || [[ "$file" == *"migration"* ]] || [[ "$file" == *"drizzle"* ]]; then
    HAS_DB=true
  fi
  if [[ "$file" == *"auth"* ]] || [[ "$file" == *"middleware"* ]]; then
    HAS_AUTH=true
  fi
done

ERRORS=0

# === TypeScript Check (only if TS files changed) ===
if [ "$HAS_TS" = true ] && [ -f "tsconfig.json" ]; then
  echo "TypeScript check..."
  if ! npx tsc --noEmit --incremental 2>/dev/null; then
    echo "TypeScript errors found" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# === Security Scan (only if API/Auth files changed) ===
if [ "$HAS_API" = true ] || [ "$HAS_AUTH" = true ]; then
  echo "Security patterns check..."

  for file in $STAGED_FILES; do
    if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
      # Check for missing auth in API routes
      if [[ "$file" == *"api/"* ]] || [[ "$file" == *"route.ts"* ]]; then
        if ! grep -q "auth()\|getUser()\|getSession()" "$file" 2>/dev/null; then
          if grep -q "export.*function\|export.*async" "$file" 2>/dev/null; then
            echo "Warning: $file: API route may be missing auth check" >&2
          fi
        fi
      fi

      # Check for raw SQL (potential injection)
      if grep -qE '\$\{.*\}.*FROM|WHERE.*\+.*\"|query\s*\(' "$file" 2>/dev/null; then
        echo "Warning: $file: Potential SQL injection risk" >&2
      fi
    fi
  done
fi

# === Database Migration Safety (only if DB files changed) ===
if [ "$HAS_DB" = true ]; then
  echo "Database safety check..."

  for file in $STAGED_FILES; do
    if [[ "$file" == *"migration"* ]] || [[ "$file" == *"schema"* ]]; then
      # Check for destructive operations without safeguards
      if grep -qiE "DROP TABLE|DROP COLUMN|TRUNCATE" "$file" 2>/dev/null; then
        echo "Warning: $file: Destructive migration detected - ensure backup exists" >&2
      fi
    fi
  done
fi

# === Dependency Security (only if deps changed) ===
if [ "$HAS_DEPS" = true ]; then
  echo "Dependency security check..."

  # Quick audit (high severity only, don't block on moderate)
  if command -v npm &> /dev/null; then
    AUDIT_RESULT=$(npm audit --audit-level=high --json 2>/dev/null | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' 2>/dev/null || echo "0")
    if [ "$AUDIT_RESULT" != "0" ] && [ "$AUDIT_RESULT" != "null" ]; then
      echo "Warning: High/critical vulnerabilities in dependencies. Run 'npm audit' for details." >&2
    fi
  fi
fi

# === Secrets Detection (always, but fast) ===
echo "Secrets check..."
for file in $STAGED_FILES; do
  if [[ "$file" != *.lock ]] && [[ "$file" != *"node_modules"* ]]; then
    # Common secret patterns
    if grep -qE "(sk_live_|sk_test_|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|-----BEGIN.*PRIVATE KEY)" "$file" 2>/dev/null; then
      echo "Error: $file: Potential secret detected!" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# === Test Check (only if source files changed, not just tests) ===
if [ "$HAS_TS" = true ] && [ "$HAS_TEST" = false ]; then
  # Source changed but no tests - just warn, don't block
  CHANGED_SRC=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx)$' | grep -v '\.test\.\|\.spec\.\|__tests__' | head -3)
  if [ -n "$CHANGED_SRC" ]; then
    # Check if related tests exist
    for src in $CHANGED_SRC; do
      TEST_FILE="${src%.ts}.test.ts"
      TEST_FILE2="${src%.tsx}.test.tsx"
      if [ ! -f "$TEST_FILE" ] && [ ! -f "$TEST_FILE2" ]; then
        echo "Tip: Consider adding tests for: $src" >&2
      fi
    done
  fi
fi

# === Final Result ===
if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "Pre-commit checks failed ($ERRORS errors)" >&2
  exit 1
fi

echo "Pre-commit checks passed"
exit 0

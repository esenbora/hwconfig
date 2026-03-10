#!/bin/bash
# pre-commit.sh - Security & Quality gate before git commit
# Event: PreToolUse (git commit)

set -e

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
cd "$PROJECT_ROOT"

echo "🔒 PRE-COMMIT SECURITY & QUALITY GATE"
echo ""

FAILED=0
WARNINGS=0

# Get staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

if [ -z "$STAGED_FILES" ]; then
    echo "No files staged for commit."
    exit 0
fi

# ===========================================
# SECURITY CHECKS (Critical)
# ===========================================
echo "🛡️  SECURITY CHECKS"
echo "-------------------------------------------"

# 1. Check for exposed API keys (NEXT_PUBLIC_ with sensitive names)
echo "1. Checking for exposed API keys..."
EXPOSED_KEYS=$(echo "$STAGED_FILES" | xargs grep -l -E "NEXT_PUBLIC_(OPENAI|STRIPE|SUPABASE_SERVICE|SECRET|API_KEY|PRIVATE)" 2>/dev/null || true)
if [ -n "$EXPOSED_KEYS" ]; then
    echo "   ❌ CRITICAL: API keys exposed with NEXT_PUBLIC_ prefix!"
    echo "   Files: $EXPOSED_KEYS"
    echo "   → Remove NEXT_PUBLIC_ prefix, use server-side only"
    FAILED=1
else
    echo "   ✅ No exposed API keys with NEXT_PUBLIC_"
fi

# 2. Check for direct database access from client components
echo "2. Checking for direct database access..."
DIRECT_DB=$(echo "$STAGED_FILES" | xargs grep -l -E "(createClient|supabase\.|firebase\.).*from ['\"]@supabase|from ['\"]firebase" 2>/dev/null | grep -E "\.(tsx|jsx)$" | grep -v "api/|server|actions" || true)
if [ -n "$DIRECT_DB" ]; then
    echo "   ⚠️  WARNING: Possible direct DB access from client components"
    echo "   Files: $DIRECT_DB"
    echo "   → Use API routes/server actions instead"
    WARNINGS=$((WARNINGS + 1))
fi

# 3. Check for hardcoded secrets
echo "3. Checking for hardcoded secrets..."
SECRET_PATTERNS="(sk_live_|pk_live_|sk_test_|-----BEGIN|api[_-]?key\s*[:=]\s*['\"][a-zA-Z0-9]|secret[_-]?key\s*[:=]\s*['\"][a-zA-Z0-9])"
HARDCODED=$(echo "$STAGED_FILES" | xargs grep -l -iE "$SECRET_PATTERNS" 2>/dev/null | grep -v "\.env" || true)
if [ -n "$HARDCODED" ]; then
    echo "   ❌ CRITICAL: Possible hardcoded secrets detected!"
    echo "   Files: $HARDCODED"
    FAILED=1
else
    echo "   ✅ No hardcoded secrets detected"
fi

# 4. Check for .env files
echo "4. Checking for .env files..."
ENV_FILES=$(echo "$STAGED_FILES" | grep -E "\.env$|\.env\.local$|\.env\.production$" || true)
if [ -n "$ENV_FILES" ]; then
    echo "   ❌ CRITICAL: .env file staged for commit!"
    echo "   Files: $ENV_FILES"
    FAILED=1
else
    echo "   ✅ No .env files staged"
fi

# 5. Check for sensitive console.logs
echo "5. Checking for sensitive logging..."
SENSITIVE_LOGS=$(echo "$STAGED_FILES" | xargs grep -l -E "console\.(log|info|debug)\s*\(\s*(user|password|token|secret|key|auth|session)" 2>/dev/null || true)
if [ -n "$SENSITIVE_LOGS" ]; then
    echo "   ⚠️  WARNING: Possible sensitive data in console.logs"
    echo "   Files: $SENSITIVE_LOGS"
    WARNINGS=$((WARNINGS + 1))
fi

# 6. Check for client-side price calculations (in tsx/jsx files)
echo "6. Checking for client-side price calculations..."
CLIENT_CALC=$(echo "$STAGED_FILES" | grep -E "\.(tsx|jsx)$" | xargs grep -l -E "(price|total|amount|cost)\s*[+\-*/=].*reduce|\.reduce.*price" 2>/dev/null | grep -v "api/|server|actions" || true)
if [ -n "$CLIENT_CALC" ]; then
    echo "   ⚠️  WARNING: Possible client-side price calculation"
    echo "   Files: $CLIENT_CALC"
    echo "   → Move calculations to server-side"
    WARNINGS=$((WARNINGS + 1))
fi

# 7. Check for SQL injection risks
echo "7. Checking for SQL injection risks..."
SQL_CONCAT=$(echo "$STAGED_FILES" | xargs grep -l -E "query\s*\(\s*['\`].*\\\$\{|WHERE.*\+.*\"|SELECT.*\+.*'" 2>/dev/null || true)
if [ -n "$SQL_CONCAT" ]; then
    echo "   ❌ CRITICAL: Possible SQL injection via string concatenation!"
    echo "   Files: $SQL_CONCAT"
    echo "   → Use parameterized queries"
    FAILED=1
else
    echo "   ✅ No SQL injection patterns detected"
fi

echo ""
# ===========================================
# QUALITY CHECKS
# ===========================================
echo "🔍 QUALITY CHECKS"
echo "-------------------------------------------"

# 8. TypeScript check
if [ -f "tsconfig.json" ]; then
    echo "8. TypeScript check..."
    if npx tsc --noEmit 2>&1; then
        echo "   ✅ TypeScript passes"
    else
        echo "   ❌ TypeScript errors found"
        FAILED=1
    fi
else
    echo "8. TypeScript check... skipped (no tsconfig.json)"
fi

# 9. ESLint check
if [ -f "eslint.config.js" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
    echo "9. ESLint check..."
    if npm run lint 2>&1 > /dev/null; then
        echo "   ✅ ESLint passes"
    else
        echo "   ⚠️  ESLint issues found (non-blocking)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "9. ESLint check... skipped (no config)"
fi

# 10. Console.log cleanup
echo "10. Console.log check..."
CONSOLE_COUNT=$(echo "$STAGED_FILES" | grep -E "\.(ts|tsx|js|jsx)$" | xargs grep -l "console\.log" 2>/dev/null | grep -v "test\|spec\|__tests__" | wc -l | tr -d ' ')
if [ "$CONSOLE_COUNT" -gt 0 ]; then
    echo "    ⚠️  $CONSOLE_COUNT files with console.log (review if intentional)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "    ✅ No console.logs in production code"
fi

# ===========================================
# SUMMARY
# ===========================================
echo ""
echo "==========================================="
if [ "$FAILED" -eq 1 ]; then
    echo "❌ PRE-COMMIT FAILED - Fix critical issues before committing"
    echo ""
    echo "Security issues MUST be fixed:"
    echo "  • No API keys in client code"
    echo "  • No .env files in commits"
    echo "  • No hardcoded secrets"
    echo "  • No SQL injection patterns"
    exit 2  # Blocking error
elif [ "$WARNINGS" -gt 0 ]; then
    echo "⚠️  PRE-COMMIT PASSED with $WARNINGS warnings"
    echo "   Review warnings before pushing to production"
else
    echo "✅ PRE-COMMIT PASSED - All checks clean"
fi
echo "==========================================="

exit 0

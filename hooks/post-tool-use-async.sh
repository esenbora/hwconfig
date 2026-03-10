#!/bin/bash
# Post Tool Use Hook (Async) - Smart background validation
# Only runs checks relevant to the changed file

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only validate Edit/Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Project-specific temp dir
PROJECT_HASH=$(pwd | md5sum | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"
mkdir -p "$TEMP_DIR"

# Track changed files for session awareness
echo "$FILE_PATH" >> "$TEMP_DIR/session-changes.log"

# === Categorize the change ===
IS_TS=false
IS_API=false
IS_AUTH=false
IS_DB=false
IS_TEST=false
IS_CONFIG=false

[[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]] && IS_TS=true
[[ "$FILE_PATH" == *.test.* || "$FILE_PATH" == *.spec.* ]] && IS_TEST=true
[[ "$FILE_PATH" == *"api/"* || "$FILE_PATH" == *"route.ts"* || "$FILE_PATH" == *"actions"* ]] && IS_API=true
[[ "$FILE_PATH" == *"auth"* || "$FILE_PATH" == *"middleware"* ]] && IS_AUTH=true
[[ "$FILE_PATH" == *"schema"* || "$FILE_PATH" == *"migration"* || "$FILE_PATH" == *"drizzle"* ]] && IS_DB=true
[[ "$FILE_PATH" == *.config.* ]] && IS_CONFIG=true

# === TypeScript Check (only for TS files, incremental) ===
if [ "$IS_TS" = true ] && [ -f "tsconfig.json" ]; then
  npx tsc --noEmit --incremental 2>&1 > "$TEMP_DIR/tsc-errors.log"
  [ $? -eq 0 ] && > "$TEMP_DIR/tsc-errors.log"
fi

# === Run Related Tests (smart detection) ===
if [ "$IS_TEST" = true ]; then
  # Test file edited - run it
  if [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      npx vitest run "$FILE_PATH" --reporter=verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      npx jest "$FILE_PATH" --verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    fi
  fi
elif [ "$IS_TS" = true ]; then
  # Source file edited - find and run related test
  TEST_FILE="${FILE_PATH%.ts}.test.ts"
  TEST_FILE2="${FILE_PATH%.tsx}.test.tsx"
  TEST_FILE3=$(echo "$FILE_PATH" | sed 's/\.tsx\?$/.spec.ts/')

  RELATED_TEST=""
  [ -f "$TEST_FILE" ] && RELATED_TEST="$TEST_FILE"
  [ -f "$TEST_FILE2" ] && RELATED_TEST="$TEST_FILE2"
  [ -f "$TEST_FILE3" ] && RELATED_TEST="$TEST_FILE3"

  if [ -n "$RELATED_TEST" ] && [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      npx vitest run "$RELATED_TEST" --reporter=verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      npx jest "$RELATED_TEST" --verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    fi
  fi
fi

# === Security Quick Check (only for API/Auth files) ===
if [ "$IS_API" = true ] || [ "$IS_AUTH" = true ]; then
  SECURITY_ISSUES=""

  # Check for missing auth in API routes
  if [[ "$FILE_PATH" == *"route.ts"* ]] || [[ "$FILE_PATH" == *"api/"* ]]; then
    if ! grep -q "auth()\|getUser()\|getSession()" "$FILE_PATH" 2>/dev/null; then
      if grep -q "export.*function\|export.*async" "$FILE_PATH" 2>/dev/null; then
        SECURITY_ISSUES="${SECURITY_ISSUES}Warning: Missing auth check in API route\n"
      fi
    fi
  fi

  # Check for potential SQL injection
  if grep -qE '\$\{.*\}.*FROM|WHERE.*\+.*\"' "$FILE_PATH" 2>/dev/null; then
    SECURITY_ISSUES="${SECURITY_ISSUES}Warning: Potential SQL injection pattern\n"
  fi

  # Check for hardcoded secrets
  if grep -qE "(sk_live_|sk_test_|password\s*=\s*['\"])" "$FILE_PATH" 2>/dev/null; then
    SECURITY_ISSUES="${SECURITY_ISSUES}Error: Potential hardcoded secret\n"
  fi

  if [ -n "$SECURITY_ISSUES" ]; then
    echo -e "$SECURITY_ISSUES" > "$TEMP_DIR/security-warnings.log"
  else
    > "$TEMP_DIR/security-warnings.log"
  fi
fi

# === Database Schema Check (only for DB files) ===
if [ "$IS_DB" = true ]; then
  DB_WARNINGS=""

  # Check for destructive operations
  if grep -qiE "DROP TABLE|DROP COLUMN|TRUNCATE" "$FILE_PATH" 2>/dev/null; then
    DB_WARNINGS="${DB_WARNINGS}Warning: Destructive migration - ensure backup\n"
  fi

  # Check for missing indexes on foreign keys
  if grep -qE "references\(" "$FILE_PATH" 2>/dev/null; then
    if ! grep -qE "\.index\(|createIndex" "$FILE_PATH" 2>/dev/null; then
      DB_WARNINGS="${DB_WARNINGS}Tip: Consider adding index for foreign key\n"
    fi
  fi

  if [ -n "$DB_WARNINGS" ]; then
    echo -e "$DB_WARNINGS" > "$TEMP_DIR/db-warnings.log"
  fi
fi

exit 0

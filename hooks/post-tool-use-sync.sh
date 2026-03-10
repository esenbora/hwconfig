#!/bin/bash
# Post Tool Use Hook (Sync) - Quick formatting only
# Keep this FAST (<5s) - runs after every edit

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only process Edit/Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Quick format based on file type
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    # Prettier only (fast)
    if [ -f "node_modules/.bin/prettier" ]; then
      npx prettier --write "$FILE_PATH" 2>/dev/null && echo "Formatted"
    fi

    # LAZY PATTERN DETECTION (instant feedback)
    LAZY=""
    grep -n "TODO\|FIXME\|XXX" "$FILE_PATH" 2>/dev/null && LAZY="${LAZY}Warning: TODO found - implement now\n"
    grep -n ": any" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}Warning: 'any' type - add proper types\n"
    grep -n "() => {}" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}Warning: Empty handler - implement it\n"
    grep -n "console\.log" "$FILE_PATH" 2>/dev/null | grep -v "// debug" | head -1 && LAZY="${LAZY}Tip: console.log - remove or show to user\n"
    grep -nE "\[.*\{.*id.*:.*name.*\}" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}Warning: Possible mock data array\n"

    if [ -n "$LAZY" ]; then
      echo -e "\nLAZY PATTERNS DETECTED:"
      echo -e "$LAZY"
    fi
    ;;
  *.go)
    gofmt -w "$FILE_PATH" 2>/dev/null && echo "Formatted"
    ;;
  *.py)
    command -v black &>/dev/null && black -q "$FILE_PATH" 2>/dev/null && echo "Formatted"
    ;;
esac

# Trigger async checks in background (don't wait)
bash ~/.claude/hooks/post-tool-use-async.sh <<< "$INPUT" &>/dev/null &

exit 0

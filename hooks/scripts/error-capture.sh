#!/bin/bash
# error-capture.sh - Capture failed commands to learnings.jsonl
# Event: PostToolUse (Bash with exitCode != 0)
#
# Environment variables available from Claude Code:
#   CLAUDE_TOOL_NAME - Tool name (e.g., "Bash")
#   CLAUDE_BASH_COMMAND - The bash command that was run
#   CLAUDE_EXIT_CODE - Exit code of the command
#   stdin - Tool output (stdout + stderr)

# Only capture bash errors
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

EXIT_CODE="${CLAUDE_EXIT_CODE:-0}"
# Only capture failures
if [ "$EXIT_CODE" -eq 0 ]; then
    exit 0
fi

# Use global memory dir (not project-specific)
GLOBAL_CLAUDE_DIR="${HOME}/.claude"
MEMORY_DIR="$GLOBAL_CLAUDE_DIR/memory"
LEARNINGS_FILE="$MEMORY_DIR/learnings.jsonl"

# Get command from environment
ERROR_CMD="${CLAUDE_BASH_COMMAND:-}"

# Read output from stdin (tool output is piped to hook)
ERROR_OUTPUT=$(cat 2>/dev/null | head -c 1000 || echo "")

# Skip if no command info
if [ -z "$ERROR_CMD" ] && [ -z "$ERROR_OUTPUT" ]; then
    exit 0
fi

# Create memory directory if needed
mkdir -p "$MEMORY_DIR"

# Create timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Escape JSON strings properly
escape_json() {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))[1:-1]' 2>/dev/null || \
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' ' | head -c 500
}

ERROR_CMD_ESCAPED=$(escape_json "$ERROR_CMD")
ERROR_OUTPUT_ESCAPED=$(escape_json "$ERROR_OUTPUT")

# Append to learnings.jsonl with atomic operation using flock
ENTRY="{\"timestamp\":\"$TIMESTAMP\",\"type\":\"error\",\"command\":\"$ERROR_CMD_ESCAPED\",\"output\":\"$ERROR_OUTPUT_ESCAPED\",\"exitCode\":$EXIT_CODE,\"resolved\":false}"

# Use flock for atomic append (prevents race conditions)
if command -v flock >/dev/null 2>&1; then
    (
        flock -x 200
        echo "$ENTRY" >> "$LEARNINGS_FILE"
    ) 200>"$LEARNINGS_FILE.lock"
else
    # Fallback: atomic write via temp file + rename pattern
    TEMP_FILE="${LEARNINGS_FILE}.tmp.$$"
    echo "$ENTRY" > "$TEMP_FILE" && cat "$TEMP_FILE" >> "$LEARNINGS_FILE" && rm -f "$TEMP_FILE"
fi

# Check for repeated errors (same command pattern)
if [ -n "$ERROR_CMD" ]; then
    # Extract first word of command for pattern matching
    CMD_PATTERN=$(echo "$ERROR_CMD" | cut -d' ' -f1)
    REPEAT_COUNT=$(grep -c "\"command\":\"$CMD_PATTERN" "$LEARNINGS_FILE" 2>/dev/null || echo "0")

    if [ "$REPEAT_COUNT" -ge 3 ]; then
        echo ""
        echo "⚠️  Similar error has occurred $REPEAT_COUNT times."
        echo "   Consider checking DONT_DO.md or trying a different approach."
    fi
fi

exit 0

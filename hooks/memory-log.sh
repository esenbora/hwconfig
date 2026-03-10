#!/bin/bash
# Memory Log Helper - Call this to log learnings/patterns during a session
# Usage: echo '{"type":"learning","message":"..."}' | bash memory-log.sh

MEMORY_DIR="$HOME/.claude/memory"
PROJECT_NAME=$(basename "$PWD")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$MEMORY_DIR/projects"

PROJECT_MEMORY="$MEMORY_DIR/projects/${PROJECT_NAME}.jsonl"
GLOBAL_LEARNINGS="$MEMORY_DIR/learnings.jsonl"

# Read input
INPUT=$(cat)

if [ -n "$INPUT" ]; then
  # Parse type and message
  TYPE=$(echo "$INPUT" | jq -r '.type // "note"' 2>/dev/null)
  MESSAGE=$(echo "$INPUT" | jq -r '.message // .note // .pattern // ""' 2>/dev/null)

  if [ -n "$MESSAGE" ]; then
    # Log to project memory
    echo "{\"ts\":\"$TIMESTAMP\",\"type\":\"$TYPE\",\"message\":\"$MESSAGE\"}" >> "$PROJECT_MEMORY"

    # Log significant learnings globally
    if [ "$TYPE" = "learning" ] || [ "$TYPE" = "pattern" ]; then
      echo "{\"ts\":\"$TIMESTAMP\",\"project\":\"$PROJECT_NAME\",\"type\":\"$TYPE\",\"message\":\"$MESSAGE\"}" >> "$GLOBAL_LEARNINGS"
    fi

    echo "Logged: [$TYPE] $MESSAGE"
  fi
fi

exit 0

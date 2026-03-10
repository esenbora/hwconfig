#!/bin/bash
# Persist Learnings Hook - Project-based memory system
# Tracks sessions, learnings, and patterns per project

MEMORY_DIR="$HOME/.claude/memory"
PROJECT_NAME=$(basename "$PWD")
PROJECT_HASH=$(echo "$PWD" | md5sum | cut -c1-8)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure memory directories exist
mkdir -p "$MEMORY_DIR/projects"

# Global session log
SESSIONS_LOG="$MEMORY_DIR/sessions.log"
LEARNINGS_FILE="$MEMORY_DIR/learnings.jsonl"

# Project-specific memory
PROJECT_MEMORY="$MEMORY_DIR/projects/${PROJECT_NAME}.jsonl"

# Get hook event from environment or stdin
HOOK_EVENT="${CLAUDE_HOOK_EVENT_NAME:-SessionStart}"

case "$HOOK_EVENT" in
  "SessionStart")
    # Log session start
    echo "$TIMESTAMP | START | $PROJECT_NAME | $PWD" >> "$SESSIONS_LOG"

    # Log to global learnings
    echo "{\"ts\":\"$TIMESTAMP\",\"event\":\"session_start\",\"project\":\"$PROJECT_NAME\",\"path\":\"$PWD\"}" >> "$LEARNINGS_FILE"

    # Log to project-specific file
    echo "{\"ts\":\"$TIMESTAMP\",\"event\":\"session_start\"}" >> "$PROJECT_MEMORY"

    # Output context from previous sessions (last 5 entries)
    if [ -f "$PROJECT_MEMORY" ]; then
      PREV_SESSIONS=$(grep -c "session_start" "$PROJECT_MEMORY" 2>/dev/null || echo "0")
      if [ "$PREV_SESSIONS" -gt 1 ]; then
        echo "=== Project Memory: $PROJECT_NAME ==="
        echo "Previous sessions: $PREV_SESSIONS"

        # Show recent patterns/learnings
        if grep -q "pattern\|learning\|note" "$PROJECT_MEMORY" 2>/dev/null; then
          echo "Recent learnings:"
          grep "pattern\|learning\|note" "$PROJECT_MEMORY" | tail -3 | while read line; do
            MSG=$(echo "$line" | jq -r '.message // .note // .pattern' 2>/dev/null)
            [ -n "$MSG" ] && echo "  - $MSG"
          done
        fi
      fi
    fi
    ;;

  "Stop"|"SessionEnd")
    # Log session end
    echo "$TIMESTAMP | END   | $PROJECT_NAME | $PWD" >> "$SESSIONS_LOG"

    # Log to global learnings
    echo "{\"ts\":\"$TIMESTAMP\",\"event\":\"session_end\",\"project\":\"$PROJECT_NAME\"}" >> "$LEARNINGS_FILE"

    # Log to project-specific file
    echo "{\"ts\":\"$TIMESTAMP\",\"event\":\"session_end\"}" >> "$PROJECT_MEMORY"
    ;;

  *)
    # For other events, just log if there's meaningful data
    ;;
esac

exit 0

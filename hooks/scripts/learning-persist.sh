#!/bin/bash
# learning-persist.sh - Persist learnings at session end
# Event: Stop

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
MEMORY_DIR="$PROJECT_ROOT/.claude/memory"
LEARNINGS_FILE="$MEMORY_DIR/learnings.jsonl"

mkdir -p "$MEMORY_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Mark session end
echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"session_end\"}" >> "$LEARNINGS_FILE"

# Count session stats
if [ -f "$LEARNINGS_FILE" ]; then
    TOTAL=$(wc -l < "$LEARNINGS_FILE" | tr -d ' ')
    ERRORS=$(grep -c '"type":"error"' "$LEARNINGS_FILE" 2>/dev/null || echo "0")
    
    echo "🧠 Memory Stats:"
    echo "   Total entries: $TOTAL"
    echo "   Errors captured: $ERRORS"
fi

exit 0

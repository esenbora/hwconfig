#!/bin/bash
# loop-detector.sh - Detect when Claude is stuck in a loop
# Event: PostToolUse (Edit, Bash)
#
# Detects patterns like:
# - Editing same file 3+ times without success
# - Running same command repeatedly
# - Making contradictory changes

set -e

GLOBAL_CLAUDE_DIR="${HOME}/.claude"
MEMORY_DIR="$GLOBAL_CLAUDE_DIR/memory"
LOOP_TRACKER="$MEMORY_DIR/loop-tracker.tmp"

TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
FILE_PATH="${CLAUDE_FILE_PATH:-}"
COMMAND="${CLAUDE_BASH_COMMAND:-}"
EXIT_CODE="${CLAUDE_EXIT_CODE:-0}"

mkdir -p "$MEMORY_DIR"
touch "$LOOP_TRACKER"

# Generate action signature
if [ -n "$FILE_PATH" ]; then
    ACTION_SIG="edit:$FILE_PATH"
elif [ -n "$COMMAND" ]; then
    # Normalize command (remove arguments that change)
    NORMALIZED_CMD=$(echo "$COMMAND" | sed 's/[0-9]\+//g' | cut -d' ' -f1-3)
    ACTION_SIG="bash:$NORMALIZED_CMD"
else
    exit 0
fi

# Add to tracker with timestamp
echo "$(date +%s):$ACTION_SIG:$EXIT_CODE" >> "$LOOP_TRACKER"

# Keep only last 20 actions
tail -20 "$LOOP_TRACKER" > "$LOOP_TRACKER.tmp" 2>/dev/null || true
mv "$LOOP_TRACKER.tmp" "$LOOP_TRACKER" 2>/dev/null || true

# Count recent occurrences of same action
RECENT_COUNT=$(grep -c "$ACTION_SIG" "$LOOP_TRACKER" 2>/dev/null || echo "0")

# Count recent failures
RECENT_FAILURES=$(grep "$ACTION_SIG:1\|$ACTION_SIG:2" "$LOOP_TRACKER" 2>/dev/null | wc -l || echo "0")

# Detect loop patterns
LOOP_DETECTED=false
LOOP_REASON=""

# Pattern 1: Same action 4+ times
if [ "$RECENT_COUNT" -ge 4 ]; then
    LOOP_DETECTED=true
    LOOP_REASON="Same action repeated $RECENT_COUNT times"
fi

# Pattern 2: 3+ failures on same action
if [ "$RECENT_FAILURES" -ge 3 ]; then
    LOOP_DETECTED=true
    LOOP_REASON="$RECENT_FAILURES consecutive failures on same action"
fi

# Pattern 3: Edit same file 3+ times (potential back-and-forth)
if [ -n "$FILE_PATH" ]; then
    EDIT_COUNT=$(grep -c "edit:$FILE_PATH" "$LOOP_TRACKER" 2>/dev/null || echo "0")
    if [ "$EDIT_COUNT" -ge 3 ]; then
        LOOP_DETECTED=true
        LOOP_REASON="Edited same file $EDIT_COUNT times - possible back-and-forth"
    fi
fi

# Output warning if loop detected
if [ "$LOOP_DETECTED" = true ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 POTENTIAL LOOP DETECTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  $LOOP_REASON"
    echo ""
    echo "STOP and consider:"
    echo "  1. Is the approach fundamentally wrong?"
    echo "  2. Am I missing something in the error message?"
    echo "  3. Should I ask the user for clarification?"
    echo "  4. Is there a DONT_DO entry I should check?"
    echo ""
    echo "💡 Options:"
    echo "  - Step back and re-analyze the problem"
    echo "  - Check DONT_DO.md for similar issues"
    echo "  - Ask user: 'I'm having trouble with X. Can you clarify Y?'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit 0

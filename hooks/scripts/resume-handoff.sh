#!/bin/bash
# resume-handoff.sh - Load last handoff on session resume
# Event: SessionStart (matcher: resume)
#
# Loads the most recent handoff file and outputs it as additionalContext

HANDOFF_DIR="${HOME}/.claude/memory/handoffs"

# Find most recent handoff
LATEST_HANDOFF=$(ls -t "$HANDOFF_DIR"/*.yaml 2>/dev/null | head -1)

if [ -z "$LATEST_HANDOFF" ] || [ ! -f "$LATEST_HANDOFF" ]; then
    # No handoff found, silent exit
    exit 0
fi

# Get handoff age in hours
HANDOFF_AGE_MINS=$(( ($(date +%s) - $(stat -f %m "$LATEST_HANDOFF" 2>/dev/null || stat -c %Y "$LATEST_HANDOFF" 2>/dev/null)) / 60 ))
HANDOFF_AGE_HOURS=$(( HANDOFF_AGE_MINS / 60 ))

# Only load if less than 24 hours old
if [ "$HANDOFF_AGE_HOURS" -gt 24 ]; then
    echo ""
    echo "ℹ️  Found old handoff (${HANDOFF_AGE_HOURS}h ago) - skipping auto-load"
    echo "   File: $LATEST_HANDOFF"
    echo "   Run: cat $LATEST_HANDOFF"
    echo ""
    exit 0
fi

# Output handoff content
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMING FROM HANDOFF"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "File: $(basename "$LATEST_HANDOFF")"
echo "Age: ${HANDOFF_AGE_MINS} minutes ago"
echo ""

# Extract key sections from handoff
if command -v grep &> /dev/null; then
    # Current task
    CURRENT_TASK=$(grep -A1 "current_task:" "$LATEST_HANDOFF" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')
    if [ -n "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "[TODO: Fill from context]" ]; then
        echo "🎯 Current Task: $CURRENT_TASK"
    fi

    # Next steps
    echo ""
    echo "📌 Next Steps:"
    grep -A10 "next_steps:" "$LATEST_HANDOFF" 2>/dev/null | grep "^  -" | head -5 | while read line; do
        echo "   $line"
    done

    # Decisions made
    DECISIONS=$(grep -A10 "decisions_made:" "$LATEST_HANDOFF" 2>/dev/null | grep "^    -" | head -3)
    if [ -n "$DECISIONS" ] && ! echo "$DECISIONS" | grep -q "TODO"; then
        echo ""
        echo "✓ Decisions Made:"
        echo "$DECISIONS" | while read line; do
            echo "   $line"
        done
    fi

    # Git branch
    GIT_BRANCH=$(grep "git_branch:" "$LATEST_HANDOFF" 2>/dev/null | cut -d'"' -f2)
    if [ -n "$GIT_BRANCH" ]; then
        echo ""
        echo "🌿 Branch: $GIT_BRANCH"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Full handoff: cat $LATEST_HANDOFF"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0

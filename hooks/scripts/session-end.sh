#!/bin/bash
# session-end.sh - Finalize session: create summary, persist learnings, cleanup
# Event: Stop
#
# Creates a session summary and persists important learnings

SESSIONS_DIR="${HOME}/.claude/memory/sessions"
PATTERNS_FILE="${HOME}/.claude/memory/patterns.yaml"
LEARNINGS_FILE="${HOME}/.claude/memory/learnings.jsonl"

SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%s)}"
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
SESSION_FILE="${SESSIONS_DIR}/${SESSION_ID}.yaml"

# Ensure directories exist
mkdir -p "$SESSIONS_DIR"

# Get project info
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Count learnings added this session (if we can track)
NEW_LEARNINGS=0
if [ -f "$LEARNINGS_FILE" ]; then
    # Count lines with today's date
    TODAY=$(date +"%Y-%m-%d")
    NEW_LEARNINGS=$(grep -c "$TODAY" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
fi

# Get git stats
GIT_COMMITS=0
GIT_BRANCH=""
if [ -d "$PROJECT_ROOT/.git" ]; then
    GIT_BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null)
    # Count commits today (rough estimate)
    GIT_COMMITS=$(cd "$PROJECT_ROOT" && git log --oneline --since="today 00:00" 2>/dev/null | wc -l | tr -d ' ')
fi

# Create session summary
cat > "$SESSION_FILE" << EOF
# Krabby Session Summary
# Session ID: ${SESSION_ID}
# Ended: ${TIMESTAMP}

metadata:
  session_id: "${SESSION_ID}"
  ended_at: "${TIMESTAMP}"
  project: "${PROJECT_NAME}"
  git_branch: "${GIT_BRANCH:-unknown}"

stats:
  git_commits: ${GIT_COMMITS}
  new_learnings: ${NEW_LEARNINGS}

# Note: Detailed summary should be filled by session-summary.sh hook
summary: "[Auto-generated session end marker]"
EOF

# Output summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SESSION ENDED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Session: ${SESSION_ID}"
echo "Project: ${PROJECT_NAME}"
if [ -n "$GIT_BRANCH" ]; then
    echo "Branch: ${GIT_BRANCH}"
fi
echo ""
echo "Stats:"
echo "  • Git commits today: ${GIT_COMMITS}"
echo "  • New learnings: ${NEW_LEARNINGS}"
echo ""

# Remind about knowledge updates
if [ "$NEW_LEARNINGS" -gt 0 ]; then
    echo "💡 New learnings captured - consider consolidating to:"
    echo "   • DONT_DO.md (if failures occurred)"
    echo "   • CRITICAL_NOTES.md (if patterns discovered)"
    echo "   • progress.txt (update Codebase Patterns)"
    echo ""
fi

# Cleanup old sessions (keep last 10)
ls -t "$SESSIONS_DIR"/*.yaml 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null

echo "Session file: ${SESSION_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

#!/bin/bash
# create-handoff.sh - Create handoff document before context compaction
# Event: PreCompact (matcher: auto)
#
# Creates a YAML handoff file that preserves session state
# for seamless context continuation.

HANDOFF_DIR="${HOME}/.claude/memory/handoffs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
HANDOFF_FILE="${HANDOFF_DIR}/${TIMESTAMP}.yaml"

# Ensure directory exists
mkdir -p "$HANDOFF_DIR"

# Get project info
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Get current git branch if available
GIT_BRANCH=""
if [ -d "$PROJECT_ROOT/.git" ]; then
    GIT_BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null)
fi

# Get recently modified files (last hour)
RECENT_FILES=""
if command -v find &> /dev/null; then
    RECENT_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) -mmin -60 2>/dev/null | head -20 | while read f; do
        echo "  - ${f#$PROJECT_ROOT/}"
    done)
fi

# Get unstaged changes
GIT_STATUS=""
if [ -d "$PROJECT_ROOT/.git" ]; then
    GIT_STATUS=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | head -20 | while read line; do
        echo "  - $line"
    done)
fi

# Create handoff file
cat > "$HANDOFF_FILE" << EOF
# Krabby Handoff Document
# Generated: $(date +"%Y-%m-%dT%H:%M:%S")
# Session: ${SESSION_ID}

metadata:
  session_id: "${SESSION_ID}"
  timestamp: "$(date +"%Y-%m-%dT%H:%M:%S")"
  project: "${PROJECT_NAME}"
  git_branch: "${GIT_BRANCH:-main}"

state:
  # Current task being worked on
  current_task: "[TODO: Fill from context]"

  # Files modified in this session
  files_modified:
${RECENT_FILES:-"    - none tracked"}

  # Key decisions made
  decisions_made:
    - "[TODO: Fill from context]"

  # Git status
  git_status:
${GIT_STATUS:-"    - clean"}

patterns_discovered:
  # New patterns learned in this session
  - "[TODO: Fill from context]"

next_steps:
  # What should be done next
  - "[TODO: Fill from context]"

blockers:
  # Any blocking issues
  - none

notes: |
  This handoff was auto-generated before context compaction.
  Review and update the [TODO] sections based on actual session context.

  To continue this work:
  1. Read this handoff file
  2. Check progress.txt for Codebase Patterns
  3. Resume from next_steps
EOF

# Output confirmation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 HANDOFF CREATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "File: ${HANDOFF_FILE}"
echo ""
echo "⚠️  Context compaction imminent!"
echo "   Session state has been preserved."
echo ""
echo "To resume later:"
echo "   - Handoff will auto-load on session resume"
echo "   - Or read: cat ${HANDOFF_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Keep only last 10 handoffs
ls -t "$HANDOFF_DIR"/*.yaml 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null

exit 0

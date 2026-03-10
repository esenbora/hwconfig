#!/bin/bash
# AI Co-Founder Daily Pipeline
# Run via cron: 0 8 * * * bash ~/.claude/cofounder/daily.sh
#
# This script creates prompt files that Claude Code reads on session start.
# It does NOT run Claude directly - it queues tasks for the next session.

COFOUNDER_DIR="$HOME/.claude/cofounder"
DATE=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%u) # 1=Monday, 7=Sunday

# Ensure directories exist
mkdir -p "$COFOUNDER_DIR"/{ideas/weekly,xposts/queue,context}

# Daily: Queue X post generation prompt
cat > "$COFOUNDER_DIR/xposts/queue/$DATE-prompt.md" << EOF
# Daily X Post Queue - $DATE

**Status:** pending
**Generated:** $DATE

## Task
Generate 3-5 X posts for @buzzicra. Mix of:
- 1-2 build in public updates (check current projects)
- 1 educational/tip post (AI tools, dev productivity, shipping fast)
- 1 hot take or opinion (optional, only if there's a good one)

Use the cofounder-xpost skill to generate these.
EOF

# Weekly (Monday): Queue idea research
if [ "$DAY_OF_WEEK" -eq 1 ]; then
  cat > "$COFOUNDER_DIR/ideas/weekly/$DATE-prompt.md" << EOF
# Weekly Idea Research - $DATE

**Status:** pending
**Generated:** $DATE

## Task
Research and score 5 new project ideas for this week.
Use the cofounder-idea skill to:
1. Scrape Product Hunt, HN, Reddit for trending topics
2. Score each idea on build speed, monetization, marketing angle
3. Recommend the top pick

Focus on ideas that can ship in under 2 weeks.
EOF
fi

echo "[$DATE] Co-founder daily tasks queued."

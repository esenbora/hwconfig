#!/bin/bash
# knowledge-loader.sh - Load knowledge files at session start
# Event: SessionStart
# v2.0 - Now outputs actual file contents for context injection

set -e

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
GLOBAL_CLAUDE_DIR="${HOME}/.claude"

echo "📚 KNOWLEDGE LOADING..."
echo ""

# ============================================
# DONT_DO.md - Failed approaches (CRITICAL)
# ============================================
if [ -f "$CLAUDE_DIR/DONT_DO.md" ]; then
    DONT_DO_COUNT=$(grep -c "^### ❌" "$CLAUDE_DIR/DONT_DO.md" 2>/dev/null || echo "0")
    if [ "$DONT_DO_COUNT" -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📛 DONT_DO.md ($DONT_DO_COUNT failed approaches)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$CLAUDE_DIR/DONT_DO.md"
        echo ""
    else
        echo "📛 DONT_DO.md: No failed approaches recorded"
    fi
else
    echo "📛 DONT_DO.md: Not found (will be created when needed)"
fi

echo ""

# ============================================
# CRITICAL_NOTES.md - Project patterns/gotchas
# ============================================
if [ -f "$CLAUDE_DIR/CRITICAL_NOTES.md" ]; then
    # Check if it has actual content (not just template)
    CONTENT_LINES=$(grep -v "^#\|^>\|^-\|^$\|^<!--\|^\*" "$CLAUDE_DIR/CRITICAL_NOTES.md" 2>/dev/null | wc -l || echo "0")
    if [ "$CONTENT_LINES" -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 CRITICAL_NOTES.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$CLAUDE_DIR/CRITICAL_NOTES.md"
        echo ""
    else
        echo "📋 CRITICAL_NOTES.md: Template only (no project-specific notes)"
    fi
else
    echo "📋 CRITICAL_NOTES.md: Not found"
fi

echo ""

# ============================================
# progress.txt - Codebase Patterns + Session Log
# ============================================
if [ -f "$PROJECT_ROOT/progress.txt" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 progress.txt (Codebase Patterns & Session Log)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$PROJECT_ROOT/progress.txt"
    echo ""
else
    echo "📊 progress.txt: Not found"
fi

echo ""

# ============================================
# AGENTS.md - Directory-specific knowledge
# ============================================
AGENTS_FOUND=0
for dir in "src" "app" "lib" "components" "services" "utils"; do
    if [ -f "$PROJECT_ROOT/$dir/AGENTS.md" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📁 AGENTS.md in $dir/"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$PROJECT_ROOT/$dir/AGENTS.md"
        echo ""
        AGENTS_FOUND=$((AGENTS_FOUND + 1))
    fi
done

if [ "$AGENTS_FOUND" -eq 0 ]; then
    echo "📁 AGENTS.md: None found in common directories"
fi

echo ""

# ============================================
# Learnings count (don't dump - too large)
# ============================================
if [ -f "$GLOBAL_CLAUDE_DIR/memory/learnings.jsonl" ]; then
    LEARNING_COUNT=$(wc -l < "$GLOBAL_CLAUDE_DIR/memory/learnings.jsonl" 2>/dev/null | tr -d ' ' || echo "0")
    echo "🧠 $LEARNING_COUNT learnings in memory (auto-searched on errors)"
fi

# ============================================
# Handoffs available
# ============================================
if [ -d "$GLOBAL_CLAUDE_DIR/memory/handoffs" ]; then
    HANDOFF_COUNT=$(ls -1 "$GLOBAL_CLAUDE_DIR/memory/handoffs"/*.yaml 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$HANDOFF_COUNT" -gt 0 ]; then
        LATEST_HANDOFF=$(ls -t "$GLOBAL_CLAUDE_DIR/memory/handoffs"/*.yaml 2>/dev/null | head -1)
        echo "📤 $HANDOFF_COUNT handoffs available (latest: $(basename "$LATEST_HANDOFF"))"
    fi
fi

# ============================================
# Sharp edges
# ============================================
if [ -f "$GLOBAL_CLAUDE_DIR/memory/sharp-edges.yaml" ]; then
    EDGE_COUNT=$(grep -c "^  SE-" "$GLOBAL_CLAUDE_DIR/memory/sharp-edges.yaml" 2>/dev/null || echo "0")
    echo "⚠️ $EDGE_COUNT sharp edges tracked (auto-matched on errors)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ KNOWLEDGE LOAD COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

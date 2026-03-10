#!/bin/bash
# session-init.sh - Initialize session, detect project type
# Event: SessionStart (startup|resume|clear)
# v5.0 - Added handoff check, memory initialization

set -e

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
SESSION_EVENT="${1:-startup}"

echo "🚀 KRABBY 2026 v5.0 SESSION INIT"
echo "═══════════════════════════════════════════════════"
echo "📅 $(date '+%Y-%m-%d %H:%M') | Event: $SESSION_EVENT"

# Detect project type
PROJECT_TYPE="unknown"

if [ -f "$PROJECT_ROOT/package.json" ]; then
    PKG=$(cat "$PROJECT_ROOT/package.json")
    
    if echo "$PKG" | grep -q '"next"'; then
        PROJECT_TYPE="nextjs"
    elif echo "$PKG" | grep -q '"expo"'; then
        PROJECT_TYPE="expo"
    elif echo "$PKG" | grep -q '"react-native"'; then
        PROJECT_TYPE="react-native"
    elif echo "$PKG" | grep -q '"react"'; then
        PROJECT_TYPE="react"
    else
        PROJECT_TYPE="node"
    fi
fi

if [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    PROJECT_TYPE="python"
fi

if [ -f "$PROJECT_ROOT/Package.swift" ]; then
    PROJECT_TYPE="swift"
fi

if [ -f "$PROJECT_ROOT/build.gradle" ] || [ -f "$PROJECT_ROOT/build.gradle.kts" ]; then
    PROJECT_TYPE="kotlin/android"
fi

echo "📦 Project Type: $PROJECT_TYPE"

# Auto-create knowledge files if they don't exist
echo ""
echo "📚 Knowledge Files:"

# Create .claude directory if needed
if [ ! -d "$PROJECT_ROOT/.claude" ]; then
    mkdir -p "$PROJECT_ROOT/.claude"
    echo "   📁 Created .claude/ directory"
fi

# Auto-create DONT_DO.md
if [ -f "$PROJECT_ROOT/.claude/DONT_DO.md" ]; then
    DONT_DO_COUNT=$(grep -c "^### ❌" "$PROJECT_ROOT/.claude/DONT_DO.md" 2>/dev/null || echo "0")
    echo "   ✓ DONT_DO.md ($DONT_DO_COUNT entries)"
else
    cat > "$PROJECT_ROOT/.claude/DONT_DO.md" << 'EOF'
# 🚫 DONT_DO - Failed Approaches Log

> Check this BEFORE solving problems to avoid repeating mistakes.

---

<!-- Add entries using: /knowledge dont-do -->
EOF
    echo "   ✨ DONT_DO.md (auto-created)"
fi

# Auto-create CRITICAL_NOTES.md
if [ -f "$PROJECT_ROOT/.claude/CRITICAL_NOTES.md" ]; then
    echo "   ✓ CRITICAL_NOTES.md"
else
    cat > "$PROJECT_ROOT/.claude/CRITICAL_NOTES.md" << 'EOF'
# 📋 Critical Notes

> Project-specific requirements, patterns, and gotchas.

---

## 🏗️ Architecture Decisions

<!-- WHY certain choices were made -->

---

## 🔧 Project-Specific Patterns

<!-- HOW this project does things differently -->

---

## ⚠️ Gotchas

<!-- Things that WILL bite you if ignored -->

---

## 🔐 Security Requirements

<!-- Non-negotiable security rules for this project -->

---

<!-- Update with: /knowledge critical -->
EOF
    echo "   ✨ CRITICAL_NOTES.md (auto-created)"
fi

# Auto-create progress.txt
if [ -f "$PROJECT_ROOT/progress.txt" ]; then
    echo "   ✓ progress.txt"
else
    cat > "$PROJECT_ROOT/progress.txt" << 'EOF'
## 🎯 Codebase Patterns

<!-- Discovered patterns go here. READ THIS FIRST in each session. -->

---

## 📋 Current Sprint

### In Progress

### Completed

---

## 📝 Session Log

<!-- Update with: /knowledge progress -->
EOF
    echo "   ✨ progress.txt (auto-created)"
fi

# Create memory directory
if [ ! -d "$PROJECT_ROOT/.claude/memory" ]; then
    mkdir -p "$PROJECT_ROOT/.claude/memory"
    touch "$PROJECT_ROOT/.claude/memory/learnings.jsonl"
    echo "   ✨ memory/ (auto-created)"
fi

if [ -f "$PROJECT_ROOT/prd.json" ]; then
    STORIES_TOTAL=$(grep -c '"id":' "$PROJECT_ROOT/prd.json" 2>/dev/null || echo "0")
    STORIES_DONE=$(grep -c '"passes": true' "$PROJECT_ROOT/prd.json" 2>/dev/null || echo "0")
    echo "   ✓ prd.json ($STORIES_DONE/$STORIES_TOTAL stories complete)"
fi

# Check for rules
if [ -d "$PROJECT_ROOT/.claude/rules" ]; then
    RULE_COUNT=$(ls -1 "$PROJECT_ROOT/.claude/rules"/*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "   ✓ rules/ ($RULE_COUNT rule files)"
fi

# v5.0: Check for handoffs
HANDOFF_DIR="${HOME}/.claude/memory/handoffs"
if [ -d "$HANDOFF_DIR" ]; then
    HANDOFF_COUNT=$(ls -1 "$HANDOFF_DIR"/*.yaml 2>/dev/null | wc -l | tr -d ' ')
    if [ "$HANDOFF_COUNT" -gt "0" ]; then
        LATEST=$(ls -t "$HANDOFF_DIR"/*.yaml 2>/dev/null | head -1)
        echo "   ✓ handoffs/ ($HANDOFF_COUNT available)"
    fi
fi

# v5.0: Check for sharp-edges
if [ -f "${HOME}/.claude/memory/sharp-edges.yaml" ]; then
    EDGE_COUNT=$(grep -c "^  - id:" "${HOME}/.claude/memory/sharp-edges.yaml" 2>/dev/null || echo "0")
    echo "   ✓ sharp-edges.yaml ($EDGE_COUNT known gotchas)"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "⚡ Ready. v5.0 Features Active:"
echo "   • Quality Gates (TypeScript + ESLint + Prettier)"
echo "   • Error Tracking + Loop Detection"
echo "   • Pre-commit Quality Checks"
echo "   • Handoff System (PreCompact)"
echo "   • Schema/Package Change Alerts"
echo ""
echo "📋 Remember:"
echo "   • Check DONT_DO.md before solving problems"
echo "   • Check Codebase Patterns in progress.txt"
echo "   • Confidence ≥85% before editing"
echo "═══════════════════════════════════════════════════"

exit 0

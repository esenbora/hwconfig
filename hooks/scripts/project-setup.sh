#!/bin/bash
# project-setup.sh - Project initialization hook
# Event: Setup (triggered by --init, --init-only, --maintenance flags)
# Claude Code v2.1.10+

set -e

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-.}"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo "🚀 PROJECT SETUP INITIATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create .claude directory structure if not exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "📁 Creating .claude directory structure..."
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/memory"

    # Create DONT_DO.md template
    if [ ! -f "$CLAUDE_DIR/DONT_DO.md" ]; then
        cat > "$CLAUDE_DIR/DONT_DO.md" << 'EOF'
# Project Anti-Patterns

> Records failed approaches. Check before implementation.

---

## Entries

<!-- Entries will be auto-added below -->

---
EOF
        echo "   ✓ Created DONT_DO.md"
    fi

    # Create CRITICAL_NOTES.md template
    if [ ! -f "$CLAUDE_DIR/CRITICAL_NOTES.md" ]; then
        cat > "$CLAUDE_DIR/CRITICAL_NOTES.md" << 'EOF'
# Critical Project Notes

> Important constraints and decisions for this project.

---

## Tech Stack Decisions
<!-- e.g., "Use Zustand not Redux", "Tailwind only" -->

---

## Architecture Constraints
<!-- e.g., "All API routes need auth middleware" -->

---

## Code Style
<!-- e.g., "No default exports", "Prefer const arrow functions" -->

---

## Known Issues
<!-- e.g., "Legacy endpoint /api/v1/users still in use" -->

---
EOF
        echo "   ✓ Created CRITICAL_NOTES.md"
    fi
fi

# Create progress.txt if not exists
if [ ! -f "$PROJECT_ROOT/progress.txt" ]; then
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
    echo "   ✓ Created progress.txt"
fi

# Detect project type and suggest setup
echo ""
echo "📦 Detecting project type..."

if [ -f "$PROJECT_ROOT/package.json" ]; then
    echo "   Found: Node.js project"

    # Check if node_modules exists
    if [ ! -d "$PROJECT_ROOT/node_modules" ]; then
        echo ""
        echo "⚠️  Dependencies not installed"
        echo "   Run: npm install (or pnpm install / yarn)"
    fi

    # Check for common configs
    [ -f "$PROJECT_ROOT/next.config.js" ] || [ -f "$PROJECT_ROOT/next.config.ts" ] && echo "   → Next.js detected"
    [ -f "$PROJECT_ROOT/tailwind.config.js" ] || [ -f "$PROJECT_ROOT/tailwind.config.ts" ] && echo "   → Tailwind CSS detected"
    [ -f "$PROJECT_ROOT/drizzle.config.ts" ] && echo "   → Drizzle ORM detected"
    [ -f "$PROJECT_ROOT/prisma/schema.prisma" ] && echo "   → Prisma detected"
fi

if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    echo "   Found: Docker project"
fi

if [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    echo "   Found: Python project"
fi

if [ -f "$PROJECT_ROOT/go.mod" ]; then
    echo "   Found: Go project"
fi

if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    echo "   Found: Rust project"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SETUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

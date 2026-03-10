#!/bin/bash
# Session Start Hook - Compact project context

# Skip verbose analysis if in home directory (no project)
if [ "$PWD" = "$HOME" ]; then
  exit 0
fi

OUTPUT=""

# Project type (one line)
if [ -f "package.json" ]; then
  FRAMEWORK=""
  grep -q '"next"' package.json 2>/dev/null && FRAMEWORK="Next.js"
  grep -q '"expo"' package.json 2>/dev/null && FRAMEWORK="Expo"
  grep -q '"react-native"' package.json 2>/dev/null && [ -z "$FRAMEWORK" ] && FRAMEWORK="React Native"
  [ -n "$FRAMEWORK" ] && OUTPUT="Project: $FRAMEWORK\n"
elif [ -f "Package.swift" ] || [ -f "*.xcodeproj" ] 2>/dev/null; then
  OUTPUT="Project: Swift/iOS\n"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  OUTPUT="Project: Python\n"
fi

# Git (one line)
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  DIRTY=""
  git diff-index --quiet HEAD -- 2>/dev/null || DIRTY=" (dirty)"
  OUTPUT="${OUTPUT}Git: $BRANCH$DIRTY\n"
fi

# Co-founder queue (compact)
CF_DIR="$HOME/.claude/cofounder"
if [ -d "$CF_DIR" ]; then
  PP=$(find "$CF_DIR/xposts/queue" -name "*-prompt.md" 2>/dev/null | wc -l | tr -d ' ')
  PI=$(find "$CF_DIR/ideas/weekly" -name "*-prompt.md" 2>/dev/null | wc -l | tr -d ' ')
  PS=""
  [ -f "$CF_DIR/context/pipeline-status.md" ] && PS=$(grep "^Phase:" "$CF_DIR/context/pipeline-status.md" 2>/dev/null | head -1)
  [ "$PP" -gt 0 ] && OUTPUT="${OUTPUT}Queue: $PP posts pending\n"
  [ "$PI" -gt 0 ] && OUTPUT="${OUTPUT}Queue: $PI ideas pending\n"
  [ -n "$PS" ] && OUTPUT="${OUTPUT}Pipeline: $PS\n"
fi

# Only output if there's something useful
[ -n "$OUTPUT" ] && echo -e "$OUTPUT"

exit 0

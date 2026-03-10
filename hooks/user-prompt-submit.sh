#!/bin/bash
# User Prompt Submit Hook - Smart Context Display
# Keep this FAST (<2s) - runs on every prompt

# Silent unless there are issues

# Project-specific temp dir
PROJECT_HASH=$(pwd | md5sum | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"

OUTPUT=""

# TypeScript errors
if [ -f "$TEMP_DIR/tsc-errors.log" ] && [ -s "$TEMP_DIR/tsc-errors.log" ]; then
  ERROR_COUNT=$(wc -l < "$TEMP_DIR/tsc-errors.log" | tr -d ' ')
  [ "$ERROR_COUNT" -gt 0 ] && OUTPUT="${OUTPUT}TS errors ($ERROR_COUNT)\n"
fi

# Test failures
if [ -f "$TEMP_DIR/test-failures.flag" ]; then
  OUTPUT="${OUTPUT}Tests FAILED\n"
  rm -f "$TEMP_DIR/test-failures.flag"
fi

# Security warnings
[ -f "$TEMP_DIR/security-warnings.log" ] && [ -s "$TEMP_DIR/security-warnings.log" ] && OUTPUT="${OUTPUT}Security warning\n"

# Only print if there are actual issues
if [ -n "$OUTPUT" ]; then
  echo -e "$OUTPUT"
fi

exit 0

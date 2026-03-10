#!/bin/bash
# Consolidated post-edit quality: TypeScript + ESLint + Prettier

# Find project root (look for package.json)
find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

PROJECT_ROOT=$(find_project_root)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0  # Not a JS/TS project
fi

cd "$PROJECT_ROOT" || exit 0

EDITED_FILE="${CLAUDE_TOOL_PATH:-}"
ERRORS=""

# 1. Prettier Format (if config exists and file is valid)
if [ -n "$EDITED_FILE" ] && [ -f "$EDITED_FILE" ]; then
    if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ] || [ -f "prettier.config.mjs" ]; then
        # Format silently, don't output unless there's an error
        npx prettier --write "$EDITED_FILE" 2>/dev/null || true
    fi
fi

# 2. TypeScript Check (if tsconfig exists)
if [ -f "tsconfig.json" ]; then
    TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
    TSC_EXIT=$?
    if [ $TSC_EXIT -ne 0 ]; then
        # Only show first 15 errors to avoid flooding
        ERRORS="❌ TypeScript errors:\n$(echo "$TSC_OUTPUT" | head -15)"
    fi
fi

# 3. ESLint Check (if eslint config exists)
if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
    if [ -n "$EDITED_FILE" ] && [ -f "$EDITED_FILE" ]; then
        LINT_OUTPUT=$(npx eslint "$EDITED_FILE" --max-warnings 0 2>&1)
        LINT_EXIT=$?
        if [ $LINT_EXIT -ne 0 ]; then
            if [ -n "$ERRORS" ]; then
                ERRORS="$ERRORS\n\n"
            fi
            ERRORS="${ERRORS}⚠️ ESLint issues:\n$(echo "$LINT_OUTPUT" | head -10)"
        fi
    fi
fi

# Output errors if any
if [ -n "$ERRORS" ]; then
    echo -e "$ERRORS"
fi

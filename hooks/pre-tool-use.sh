#!/bin/bash
# Pre Tool Use Hook - Guard dangerous operations
# Uses CLAUDE_HOOK_* env vars (fast, no JSON parsing)

FILE_PATH="${CLAUDE_HOOK_ARGS_file_path:-}"
COMMAND="${CLAUDE_HOOK_ARGS_command:-}"
TOOL="${CLAUDE_HOOK_TOOL_NAME:-}"

# === Protected Files ===
PROTECTED_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "Podfile.lock"
  ".git/"
)

for protected in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == *"$protected"* ]]; then
    echo "BLOCKED: $protected is protected" >&2
    exit 2
  fi
done

# === Forbidden Directories ===
FORBIDDEN_DIRS=(
  "node_modules/"
  ".next/"
  "dist/"
  "build/"
  ".expo/"
)

for dir in "${FORBIDDEN_DIRS[@]}"; do
  if [[ "$FILE_PATH" == *"$dir"* ]]; then
    echo "BLOCKED: Cannot write to $dir (generated)" >&2
    exit 2
  fi
done

# === System Paths ===
SYSTEM_PATHS=("/etc/" "/usr/" "/bin/" "/sbin/" "/System/" "/Library/")

for sys in "${SYSTEM_PATHS[@]}"; do
  if [[ "$FILE_PATH" == "$sys"* ]]; then
    echo "BLOCKED: System directory" >&2
    exit 2
  fi
done

# === Dangerous Bash Commands ===
if [[ "$TOOL" == "Bash" && -n "$COMMAND" ]]; then
  # These patterns are caught by settings.json prompts, but double-check
  if echo "$COMMAND" | grep -qE "rm -rf /|rm -rf ~|sudo rm|DROP DATABASE|DROP TABLE"; then
    echo "BLOCKED: Dangerous command" >&2
    exit 2
  fi
fi

exit 0

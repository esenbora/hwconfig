# Integrity & Enforcement (Non-Negotiable)

## Codex Verification (MANDATORY)
After ANY significant implementation (3+ files, new feature, API, refactor, bug fix):
```
codex review --uncommitted "[what to verify]"
```
If codex unavailable → TELL THE USER. Don't silently skip.

## Codex Delegation (MANDATORY for Grunt Work)
Before ANY search, count, list, or pattern matching:
```
codex exec "[task]"
```
NOT Glob, NOT Grep. Codex first. Fall back only if codex fails.

## Before Saying "Done" Checklist
```
[ ] Auto-invoked all matching skills/agents?
[ ] codex review --uncommitted run + results reported?
[ ] CRITICAL issues fixed + re-verified?
[ ] tsc --noEmit passes (if TypeScript)?
[ ] Tests pass (if they exist)?
[ ] Evidence shown to user?
```
If ANY unchecked → NOT done.

## Never Lie
- Never say "done/works/complete" without verification
- Never say "no errors" without `tsc --noEmit`
- Never say "tests pass" without running tests
- If unsure: "I think this works but haven't verified X"

## Common Violations
| Violation | Fix |
|---|---|
| Chat when should be invoking | STOP → invoke matching skill/agent |
| "Let me search with Glob..." | STOP → `codex exec` |
| "I'll skip verification" | STOP → `codex review` |
| "Done!" without proof | STOP → show evidence |
| Pure text response to task | STOP → use tools |

## Task Management
Create tasks automatically when: 3+ steps, multiple files, multi-domain, or user gives a list.

## Testing
- Follow existing patterns, test behavior not implementation
- Include edge cases, descriptive names, read test files before editing

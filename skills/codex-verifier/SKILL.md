---
name: codex-verifier
description: After implementing code, use Codex CLI as a second agent to verify implementations against project standards, skills, and best practices. Auto-trigger after significant implementations before claiming "done."
---

# Codex Verifier Protocol

## Overview

**Two-agent workflow:** Claude implements, Codex verifies. Never mark work as "done" without a second pair of eyes.

```
Claude (Implement) → Codex (Verify) → Claude (Fix if needed) → Done
```

## When to Trigger (Auto-Invoke)

**ALWAYS run verification after:**
- Implementing a new feature (3+ files changed)
- Building a new API endpoint
- Creating/modifying UI components with business logic
- Refactoring existing code
- Fixing bugs (verify the fix doesn't break anything)
- Any work the user will ship to production

**SKIP verification for:**
- Single-line fixes (typos, config tweaks)
- Documentation-only changes
- Adding comments or type annotations
- File renames with no logic changes

## Verification Commands

### 1. Full Implementation Review (Primary)

After completing implementation, review all uncommitted changes:

```bash
codex review --uncommitted "$(cat <<'PROMPT'
You are a senior code reviewer. Review these changes against the following checklist:

SECURITY:
- [ ] No API keys or secrets in client code
- [ ] All API endpoints check authentication
- [ ] All API endpoints check authorization/ownership
- [ ] All user inputs sanitized
- [ ] All database queries parameterized
- [ ] No sensitive data in console.log
- [ ] Error messages don't leak internals

CODE QUALITY:
- [ ] No `any` types in TypeScript
- [ ] All states handled: loading, error, empty, success
- [ ] Error handling shows user feedback (not just console.log)
- [ ] No TODO/FIXME comments left behind
- [ ] No mock/fake data - uses real API/DB
- [ ] No empty handlers or placeholder functions

PATTERNS:
- [ ] API routes follow: auth → validate → ownership → execute
- [ ] UI components handle all states (loading/error/empty/success)
- [ ] Forms have validation + loading state + user feedback
- [ ] Server-side calculations for prices/scores/permissions

BUGS:
- [ ] No race conditions
- [ ] No memory leaks (missing cleanup, unsubscribed listeners)
- [ ] No null/undefined access without guards
- [ ] Edge cases handled (empty arrays, missing fields, network failures)

COMPLETENESS:
- [ ] Feature works end-to-end (not partially implemented)
- [ ] All acceptance criteria met
- [ ] No dead code introduced

For each issue found, specify:
1. File and line number
2. Severity: CRITICAL / WARNING / INFO
3. What's wrong
4. How to fix it

If everything passes, say: "VERIFIED: All checks passed."
PROMPT
)"
```

### 2. Targeted Verification (Specific Concerns)

When you want Codex to check something specific:

```bash
codex exec -s read-only "Review the files I just changed and verify: [SPECIFIC CONCERN]. Check the implementation thoroughly and report any issues."
```

Examples:
```bash
# Auth verification
codex exec -s read-only "Check all API routes in app/api/ for proper authentication and authorization. Every route must call auth() and verify ownership before data access."

# Type safety
codex exec -s read-only "Run through all TypeScript files changed recently and find any 'any' types, missing type annotations on function parameters, or unsafe type assertions."

# State handling
codex exec -s read-only "Check all React components in the recent changes. Every component that fetches data must handle loading, error, and empty states. Report any that don't."

# Security scan
codex exec -s read-only "Scan recent changes for security issues: exposed secrets, missing input validation, SQL injection risks, XSS vulnerabilities, or client-side privilege checks."
```

### 3. Branch Review (Before PR)

Review all changes on the current branch against main:

```bash
codex review --base main "Review all changes on this branch for production readiness. Check security, error handling, type safety, and completeness. Flag anything that would fail a senior engineer's code review."
```

### 4. Post-Fix Verification

After fixing a bug, verify the fix:

```bash
codex exec -s read-only "I just fixed a bug in [FILE]. Verify: 1) The fix addresses the root cause, not just symptoms. 2) No regressions introduced. 3) Edge cases covered. 4) Related code paths still work correctly."
```

## Workflow Integration

### Standard Implementation Flow

```
1. Claude implements the feature
2. Claude runs: codex review --uncommitted (with verification prompt)
3. Codex returns findings
4. If CRITICAL issues → Claude fixes them → re-verify
5. If WARNING issues → Claude fixes or documents why skipped
6. If clean → Claude reports "Done" with verification proof
```

### Reporting Results to User

After Codex verification, always report:

```
## Verification Results (Codex)

**Status:** PASSED / FAILED (N issues)

### Issues Found:
- [CRITICAL] auth.ts:45 - Missing ownership check on DELETE endpoint → Fixed
- [WARNING] UserCard.tsx:12 - No empty state handler → Added

### Verified Clean:
- Security checks: Passed
- Type safety: Passed
- State handling: Passed
- Error handling: Passed
```

## Output Capture

For complex verifications, capture output to a file:

```bash
codex review --uncommitted -o /tmp/codex-review.md "$(cat <<'PROMPT'
[verification prompt here]
PROMPT
)"
```

Then read `/tmp/codex-review.md` for the full report.

## Red Flags - Must Verify

These patterns ALWAYS require Codex verification:

| Pattern | Why |
|---------|-----|
| New API endpoint | Auth/authz mistakes are critical |
| Payment/pricing logic | Must be server-side, must be correct |
| User data handling | Privacy, security, data integrity |
| Authentication changes | Highest-risk code in any app |
| Database migrations | Irreversible in production |
| Multi-file refactors | Regressions hide in connected code |
| Copy-pasted code | Often contains bugs from the source |

## Common Verification Prompts

### After Building a Feature
```
"Verify this feature implementation is complete and production-ready. Check all files changed for security, error handling, type safety, and edge cases."
```

### After Building UI
```
"Review these UI components. Check: all states handled (loading/error/empty/success), accessibility basics (alt text, aria labels, keyboard nav), responsive design, and proper error boundaries."
```

### After Building API
```
"Review these API routes. Every route must: 1) Check auth, 2) Validate input with zod/schema, 3) Verify resource ownership, 4) Return safe error messages, 5) Handle all error cases."
```

### After Fixing a Bug
```
"I fixed a bug where [description]. Verify the fix is correct, complete, and doesn't introduce regressions. Check related code paths."
```

## The Rule

```
NEVER say "done" without Codex verification on significant changes.
Claude implements. Codex verifies. Then it's done.
```

Two agents are better than one. Trust but verify.

# Enterprise Development Standards

**This file defines non-negotiable standards for all skills and agents.**

---

## Parallel Work Principle (MANDATORY)

**Always maximize parallel execution:**

| Situation | Action |
|-----------|--------|
| Independent tasks | Run simultaneously |
| Independent tool calls | Send in single message |
| Independent agents | Launch in parallel |
| Multi-domain request | Multiple agents at once |

**Auto-Invoke Rule:** When keywords match an agent/skill, invoke it immediately. Don't ask permission.

| Keywords | Auto-Invoke |
|----------|-------------|
| Swift, SwiftUI, Xcode, iOS native | `mobile-ios` agent |
| Search, find, count, list, pattern | `codex exec` first |
| UI, component, React, Next.js | `frontend` agent |
| API, database, endpoint | `backend` agent |
| Bug, error, fix, debug | `quality` agent |

**Grunt work (search/count/list) → codex first. No exceptions.**

---

## Anti-Laziness Rules (CRITICAL)

### NEVER Do These

| Lazy Pattern | Why It's Bad | What To Do Instead |
|--------------|--------------|-------------------|
| Mock data | Ships fake UX, hides real bugs | Wire to real API/DB from start |
| Hardcoded values | Breaks in prod, unmaintainable | Use env vars, config, or DB |
| `// TODO: implement later` | Never gets done, ships broken | Implement now or don't commit |
| Placeholder functions | Empty shells that lie | Full implementation or nothing |
| `console.log` for errors | No user feedback, silent failures | Proper error handling + UI |
| Skipping edge cases | Crashes in prod | Handle empty, null, error states |
| `any` type | Defeats TypeScript entirely | Proper types or `unknown` with guards |
| Copy-paste code | Tech debt, bugs multiply | Extract properly or accept duplication |

### Always Do These

```
Before saying "done":
[] Does it work with REAL data? (not mocks)
[] Does it handle errors gracefully?
[] Does it handle empty states?
[] Does it handle loading states?
[] Would I ship this to paying users TODAY?
[] Would a senior engineer approve this PR?
```

---

## Definition of Done

**A feature is NOT done until:**

1. **Functional** - Works end-to-end with real data
2. **Tested** - Has tests that actually verify behavior
3. **Type-safe** - `tsc --noEmit` passes, no `any`
4. **Handles failure** - Errors don't crash, show user feedback
5. **Handles edge cases** - Empty, loading, boundary conditions
6. **Secure** - Auth, validation, ownership checks
7. **Verified** - Manually tested or browser-verified

**NOT done if:**
- Uses mock/fake data
- Has TODO comments
- Has placeholder implementations
- Skips error handling
- Missing loading/empty states
- Has `any` types
- Has `console.log` instead of proper handling

---

## Code Quality Gates

### Gate 1: Type Safety
```bash
npx tsc --noEmit
# MUST pass with ZERO errors
# NO @ts-ignore, NO @ts-expect-error (except rare documented cases)
```

### Gate 2: No Lazy Patterns
```bash
# These patterns MUST NOT exist in committed code:
grep -r "TODO" --include="*.ts" --include="*.tsx"        # No TODOs
grep -r "FIXME" --include="*.ts" --include="*.tsx"       # No FIXMEs
grep -r "mock" --include="*.ts" --include="*.tsx"        # No mock data (except test files)
grep -r ": any" --include="*.ts" --include="*.tsx"       # No any types
grep -r "console.log" --include="*.ts" --include="*.tsx" # No console.log (use logger)
```

### Gate 3: Tests
```bash
npm test
# Related tests MUST pass
# New features SHOULD have tests
```

### Gate 4: Security
```
[] Auth check present on protected routes
[] Input validated with Zod
[] Ownership check on resource access
[] No secrets in code
```

---

## Implementation Standards

### API Endpoints

**Every endpoint MUST have:**
```typescript
export async function POST(request: Request) {
  // 1. AUTH (required)
  const { userId } = await auth()
  if (!userId) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  // 2. VALIDATION (required)
  const body = await request.json()
  const result = Schema.safeParse(body)
  if (!result.success) {
    return Response.json({ error: 'Invalid input', details: result.error.flatten() }, { status: 400 })
  }

  // 3. OWNERSHIP (if accessing resource)
  const resource = await db.findUnique({ where: { id: result.data.id } })
  if (!resource || resource.userId !== userId) {
    return Response.json({ error: 'Not found' }, { status: 404 }) // Don't reveal existence
  }

  // 4. BUSINESS LOGIC with try/catch
  try {
    const data = await performOperation(result.data)
    return Response.json(data)
  } catch (error) {
    console.error('Operation failed:', error) // Log details internally
    return Response.json({ error: 'Operation failed' }, { status: 500 }) // Generic to user
  }
}
```

### UI Components

**Every component MUST handle:**
```typescript
// LAZY - Missing states
function UserList({ users }) {
  return users.map(u => <div>{u.name}</div>)
}

// COMPLETE - All states handled
function UserList({ users, isLoading, error }) {
  if (isLoading) return <Skeleton count={5} />
  if (error) return <ErrorState message="Failed to load users" onRetry={refetch} />
  if (!users?.length) return <EmptyState message="No users yet" action={<CreateButton />} />

  return users.map(u => <UserCard key={u.id} user={u} />)
}
```

### Forms

**Every form MUST have:**
```typescript
// LAZY
<form onSubmit={handleSubmit}>
  <input name="email" />
  <button>Submit</button>
</form>

// COMPLETE
<form onSubmit={handleSubmit}>
  <Input
    {...register('email')}
    error={errors.email?.message}
    disabled={isSubmitting}
  />
  <Button
    type="submit"
    disabled={isSubmitting}
    loading={isSubmitting}
  >
    {isSubmitting ? 'Submitting...' : 'Submit'}
  </Button>
  {submitError && <ErrorMessage>{submitError}</ErrorMessage>}
</form>
```

---

## Red Flags That Block Completion

If you see any of these, the work is NOT done:

| Red Flag | Action |
|----------|--------|
| `data: any` | Add proper types |
| `// TODO` | Implement or remove |
| `mockData` / `fakeData` | Wire to real source |
| `console.log` in non-debug code | Use proper error handling |
| Missing `catch` on async | Add error handling |
| No loading state on async UI | Add loading indicator |
| No error state on async UI | Add error boundary/message |
| No empty state on lists | Add empty state UI |
| API without auth check | Add authentication |
| Resource access without ownership check | Add authorization |
| User input without validation | Add Zod schema |

---

## Verification Evidence

When completing work, provide CONCRETE evidence:

```markdown
## Implementation Complete

### Evidence
- TypeScript: `tsc --noEmit` (0 errors)
- Tests: `npm test` (12 passing, 0 failing)
- Build: `npm run build`

### States Handled
- [x] Loading state with skeleton
- [x] Error state with retry button
- [x] Empty state with call-to-action
- [x] Success state with data

### Security
- [x] Auth check on API route
- [x] Zod validation on input
- [x] Ownership check on resource access

### How to Verify
1. Go to /users
2. Click "Add User"
3. Fill form with invalid email -> See validation error
4. Fill form correctly -> See success toast
5. Refresh page -> See new user in list
```

---

## Model Selection Guide

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| Implementation (frontend/backend) | opus | Coding requires deepest reasoning |
| Code review | opus | Must catch subtle issues |
| Debugging | opus | Root cause analysis needs depth |
| Security audit | opus | Critical, no shortcuts |
| Verification | opus | Must catch all gaps |
| Architecture decisions | opus | High-stakes decisions |
| Codebase exploration (read-only) | sonnet | Large context, no code changes |
| Research, reading docs | sonnet | Information gathering |

**Default to opus for any coding. Sonnet for read-only tasks.**

---

## Honesty Requirements (NO LYING)

### Before Claiming "Done"

1. **Actually run the checks** - don't assume they pass
2. **Show real output** - not "it works", show the actual result
3. **Admit uncertainty** - "I'm not sure if X" is better than guessing
4. **Surface problems** - don't hide errors, bring them up

### Forbidden Phrases (unless true with evidence)

- ~~"This should work"~~ -> Run it and confirm
- ~~"I've implemented X"~~ -> Show the code AND verification
- ~~"Tests pass"~~ -> Show the actual test output
- ~~"No errors"~~ -> Show tsc output

### Required Phrases When Uncertain

- "I haven't verified this yet"
- "I'm not sure about X, let me check"
- "This might have issues with Y"
- "I need to test this to confirm"

### Self-Check Before Completion

```
[] Did I actually run tsc? (not just assume)
[] Did I actually test this? (not just write it)
[] Am I certain it works, or hoping it works?
[] If this breaks in production, would I be surprised?
```

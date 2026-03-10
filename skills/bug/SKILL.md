---
name: bug
description: Use when something is broken, not working, showing errors, or behaving unexpectedly. Systematic debugging with TDD. Triggers on: bug, fix, broken, not working, error, crash, issue, problem, doesn't work, failed, failing, wrong, unexpected.
argument-hint: "<bug-description-or-error>"
version: 1.0.0
context: fork
agent: tdd-guide
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---


## ORCHESTRATION

```yaml
Skills:
  Always:
    - systematic-debugging    # Root cause before fix
    - defensive-coding        # Edge cases & validation
    - type-safety             # TypeScript strict
    - tdd                     # Write test for bug

  Load Based on Bug Type:
    - react-deep              # If React component bug
    - nextjs-deep             # If Next.js/routing bug
    - prisma-deep / drizzle-deep  # If database bug
    - react-query-deep        # If data fetching bug

Agents:
  Lead: quality               # Quality agent leads debugging
  Consult:
    - frontend                # If UI bug
    - backend                 # If API/server bug
    - data                    # If database bug
    - security                # If security-related

Knowledge:
  Read First:
    - DONT_DO.md              # Check if similar bug solved before
    - CRITICAL_NOTES.md       # Project patterns that might affect
    - progress.txt            # Recent changes that might relate

  Update After:
    - DONT_DO.md              # Add bug as anti-pattern
    - progress.txt            # Log bug fix
```

---

## GOLDEN RULE

```
┌──────────────────────────────────────────────────────────────────┐
│                  NO FIX WITHOUT ROOT CAUSE                       │
│                                                                  │
│  1. UNDERSTAND the bug completely                                │
│  2. FIND the root cause                                          │
│  3. THEN (and only then) FIX it                                  │
│  4. WRITE a test to prevent regression                           │
└──────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: UNDERSTAND

### Gather Information

**Ask if not provided:**

| Question | Why It Matters |
|----------|----------------|
| Expected behavior? | Know what "fixed" looks like |
| Actual behavior? | Know what's broken |
| Steps to reproduce? | Verify the fix works |
| When did it start? | Narrow down cause |
| Exact error message? | Find error source |
| Environment? | Dev/prod differences |

### Document the Bug

```markdown
## Bug Report

**Expected:** [What should happen]
**Actual:** [What is happening]
**Environment:** [Dev/Prod/Browser/etc]

**Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Bug occurs]

**Error:**
```
[Exact error message/stack trace]
```

**Frequency:** [Always / Sometimes / Rare]
```

### Create Todo List

```
TodoWrite: Create debugging tasks

- [ ] Document bug clearly
- [ ] Investigate root cause
- [ ] Find all related occurrences
- [ ] Design minimal fix
- [ ] Implement fix
- [ ] Write regression test
- [ ] Verify fix works
- [ ] Update DONT_DO.md
```

---

## PHASE 2: INVESTIGATE

### Delegate: Explore Agent

Use Task tool with Explore agent to:
- Find the code location
- Understand data flow
- Find similar patterns

### Check Recent Changes

```bash
# What changed recently?
git log --oneline -20

# Diff against working state
git diff HEAD~5 -- path/to/affected/

# Find when bug was introduced
git bisect start
git bisect bad HEAD
git bisect good <last-working-commit>
```

### Trace the Data Flow

```markdown
## Data Flow Analysis

**Entry Point:** [Where data enters]
  ↓
**Step 1:** [Transformation/function]
  ↓
**Step 2:** [Transformation/function]
  ↓
**Failure Point:** [Where it breaks] ← ROOT CAUSE HERE
  ↓
**Exit Point:** [Where error surfaces]
```

### Read the Code

**MANDATORY:** Read ALL files in the data flow before forming a hypothesis.

---

## PHASE 3: ROOT CAUSE

### Bug Categories

| Category | Error Signs | Common Cause |
|----------|-------------|--------------|
| **Null/undefined** | "Cannot read property" | Missing optional chain |
| **Type mismatch** | Wrong data format | String vs Number, different shape |
| **Race condition** | Intermittent failures | Async timing issues |
| **Logic error** | Wrong output | Bad conditional, off-by-one |
| **State bug** | Stale/wrong data | Missing re-render, cache |
| **API change** | "undefined is not a function" | Breaking dependency change |
| **Environment** | Works locally, fails in prod | Missing env var, different config |

### Document Root Cause

```markdown
## Root Cause Analysis

**Category:** [Type from table above]
**Location:** `file.ts:123`
**Exact Cause:** [Why it's broken]

**Why Not Caught:**
- [ ] Missing test coverage
- [ ] Edge case not considered
- [ ] Type system didn't catch it
- [ ] Works in isolation, fails in integration
```

### Verify Root Cause

Before fixing, confirm:
- [ ] Can explain WHY it fails
- [ ] Can predict WHEN it fails
- [ ] Understand the FIX needed

---

## PHASE 4: PLAN FIX

### Design Minimal Fix

```markdown
## Fix Plan

**Change:** [Exactly what to change]
**Files:** [List files to modify]
**Lines:** [Approximate line numbers]

**Risk Assessment:**
- [ ] Could this break other features?
- [ ] Are there similar patterns to fix?
- [ ] Need to update types?
- [ ] Need migration/data fix?

**Verification:**
- [ ] How to test the fix
- [ ] What edge cases to check
```

### Check for Similar Issues

```bash
# Find same pattern elsewhere
grep -rn "same-buggy-pattern" src/

# If found, plan to fix all instances
```

**If systemic:** Fix all occurrences, not just the reported one.

---

## PHASE 5: IMPLEMENT

### Fix Rules

```
1. MINIMAL change - Only fix the bug
2. NO refactoring - Save for later
3. ONE fix at a time - Don't batch
4. PRESERVE behavior - Don't change working code
5. MATCH patterns - Follow existing code style
```

### Apply Fix

```typescript
// ❌ Before (buggy)
const name = user.profile.name // Crashes if profile null

// ✅ After (fixed)
const name = user?.profile?.name ?? 'Unknown'
```

### Update Todos

Mark implementation complete.

---

## PHASE 6: WRITE TEST

### Delegate: Quality Agent

**Write regression test BEFORE verifying manually:**

```typescript
import { describe, it, expect } from 'vitest'

describe('Bug #123 - User profile null crash', () => {
  it('handles null profile gracefully', () => {
    // Arrange
    const user = { id: '1', profile: null }

    // Act
    const result = getUserName(user)

    // Assert
    expect(result).toBe('Unknown')
  })

  it('handles undefined user gracefully', () => {
    expect(() => getUserName(undefined)).not.toThrow()
  })
})
```

**Test must:**
- Reproduce the original bug scenario
- Pass with the fix applied
- Fail if fix is removed

---

## PHASE 7: VERIFY

### Verification Checklist

```markdown
## Verification

**Bug Fix:**
- [ ] Original bug no longer reproduces
- [ ] Fix works in all affected scenarios
- [ ] Edge cases handled

**No Regressions:**
- [ ] Related features still work
- [ ] TypeScript passes: `npx tsc --noEmit`
- [ ] Lint passes: `npm run lint`
- [ ] All tests pass: `npm test`

**Evidence:**
[Show output proving bug is fixed]
```

### Test Edge Cases

- What if input is empty/null/undefined?
- What if user is not authenticated?
- What if network fails during operation?
- What if concurrent requests happen?

---

## PHASE 8: PREVENT

### Update DONT_DO.md

```markdown
## YYYY-MM-DD | BUG

### ❌ [Brief description of bug]

**Context:** [What the code was trying to do]
**Symptom:** [What users saw]
**Root Cause:** [Why it happened]
**✅ Solution:** [The fix pattern]
**Prevention:** [How to avoid in future]

\`\`\`typescript
// ❌ Don't do this
[buggy code]

// ✅ Do this instead
[fixed code]
\`\`\`
```

### Update progress.txt

```markdown
## YYYY-MM-DD HH:MM - Bug Fix: [description]
- Root cause: [what was wrong]
- Fix: [what was changed]
- Test added: [test file]
- **Learnings:** [what to remember]
```

---

## PHASE 9: COMMIT

### Commit Message Format

```
fix: [brief description]

Root cause: [what caused it]
Solution: [what fixed it]
Test: [test added]

Closes #[issue-number]
```

---

## RED FLAGS - STOP IMMEDIATELY

```
🚨 If you catch yourself:

"Quick fix for now"       → STOP - Find root cause
"Just try changing X"     → STOP - Understand first
Multiple fixes at once    → STOP - One at a time
"I don't understand but"  → STOP - Investigate more
3+ failed fix attempts    → STOP - Question hypothesis
"It works on my machine"  → STOP - Check environment diff
```

### When to Escalate

After 3 failed hypotheses:
1. Document what you've tried
2. Share investigation findings
3. Ask for help / pair debug

---

## OUTPUT

```markdown
## Bug Fix Summary

**Bug:** [Description]
**Root Cause:** [Category: specific cause]
**Location:** `file.ts:123`

**Fix:**
\`\`\`typescript
// Before
[buggy code]

// After
[fixed code]
\`\`\`

**Files Changed:**
- `path/file.ts` - [what changed]

**Test Added:**
- `path/file.test.ts` - [test description]

**Verification:**
- [ ] Bug no longer reproduces
- [ ] Tests pass
- [ ] TypeScript passes

**Prevention:**
- DONT_DO.md updated: [Yes/No]
- Regression test added: [Yes/No]
```

---

## QUICK REFERENCE: Debugging Checklist

```
□ Bug documented clearly
□ Checked DONT_DO.md for similar issues
□ Data flow traced
□ Root cause identified (not guessed)
□ Root cause verified
□ Minimal fix designed
□ Similar patterns checked
□ Fix implemented
□ Regression test written
□ All tests pass
□ TypeScript passes
□ DONT_DO.md updated
□ Evidence provided
```

---

## MOBILE PLATFORM

> FIX ON ONE = VERIFY ON BOTH

### Mobile-Specific Agents

```yaml
Agents:
  Lead: quality               # Quality agent leads debugging
  Consult:
    - mobile-rn               # React Native issues
    - mobile-ios              # iOS-specific
    - mobile-android          # Android-specific

Quality Gates:
  - typecheck
  - lint
  - test
  - ios-verify
  - android-verify
  - regression-check
```

### Mobile Bug Report Template

```markdown
## Mobile Bug Report

**Platform:** iOS / Android / Both
**Device:** [Model + OS version]
**Build:** Dev / TestFlight / Production

**Expected:** [What should happen]
**Actual:** [What is happening]
**Reproduce:**
1. [Step 1]
2. [Step 2]

**Error:** [From Metro console / Crashlytics]
```

### Mobile-Specific Questions

1. **Platform:** iOS, Android, or both?
2. **Device:** Physical device or simulator/emulator?
3. **Device model:** iPhone 15, Pixel 8, etc.?
4. **OS version:** iOS 17, Android 14, etc.?
5. **App version:** Dev build, TestFlight, Production?
6. **Reproducible:** Always, sometimes, rare?

### Clear Cache First (IMPORTANT)

```bash
# Clear Metro cache
npx expo start --clear

# Clear watchman
watchman watch-del-all

# Clean iOS build
cd ios && rm -rf build && pod install

# Clean Android build
cd android && ./gradlew clean
```

### Check Platform-Specific

```bash
# Check if iOS only
npx expo run:ios

# Check if Android only
npx expo run:android

# Check Metro logs
# Check Xcode console (iOS)
# Check Logcat (Android)
```

### Common Mobile Bug Sources

| Symptom | Likely Cause |
|---------|--------------|
| Crash on iOS only | Native module issue |
| Crash on Android only | Native module issue |
| White screen | JS error, check Metro |
| Frozen UI | Infinite loop, heavy render |
| Navigation broken | State issue, back handler |
| Keyboard covers input | KeyboardAvoidingView missing |
| Safe area issues | SafeAreaView missing |
| List janky | Not using FlashList |
| Images broken | URI vs require path |

### Platform-Specific Investigation

```typescript
import { Platform } from 'react-native'

console.log('Platform:', Platform.OS)
console.log('Version:', Platform.Version)

if (Platform.OS === 'ios') {
  console.log('iOS specific debug')
}
```

### Common Mobile Fixes

```typescript
// Safe area issue
// Missing
<View><Content /></View>
// Fixed
<SafeAreaView><Content /></SafeAreaView>

// Keyboard issue
// Missing
<View><TextInput /></View>
// Fixed
<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
>
  <TextInput />
</KeyboardAvoidingView>

// Android back button
// With handler
useFocusEffect(
  useCallback(() => {
    const onBackPress = () => {
      // Handle back
      return true
    }
    BackHandler.addEventListener('hardwareBackPress', onBackPress)
    return () => BackHandler.removeEventListener('hardwareBackPress', onBackPress)
  }, [])
)
```

### Mobile Fix Rules

1. **Test on BOTH platforms** - Even if bug is on one
2. **Test on REAL device** - Simulators miss issues
3. **Clear cache after fix** - Metro caches aggressively
4. **One fix at a time** - Easier to verify

### Mobile Verification Checklist

```markdown
- [ ] Bug fixed on iOS simulator
- [ ] Bug fixed on Android emulator
- [ ] Bug fixed on iOS device
- [ ] Bug fixed on Android device
- [ ] No regressions on other platform
- [ ] TypeScript passes
- [ ] Metro shows no errors
- [ ] Tests pass (if applicable)
```

### Mobile Bug Fix Output

```markdown
## Mobile Bug Fix Summary

**Bug:** [Description]
**Platform:** iOS / Android / Both
**Root Cause:** [What was wrong]
**Fix:** [What was changed]

**Tested On:**
- [ ] iOS Simulator
- [ ] iOS Device ([model])
- [ ] Android Emulator
- [ ] Android Device ([model])

**Files Changed:**
- [file]: [change]

**Prevention:** [How to avoid in future]
```

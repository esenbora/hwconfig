---
name: systematic-debugging
description: Use when encountering ANY bug, error, or unexpected behavior. Find root cause before fixing. Triggers on: debug, bug, error, fix, broken, not working, crash, issue, investigate, why, failing.
version: 2.0.0
tier: 1
triggers:
  - bug
  - error
  - fix
  - crash
  - broken
  - not working
integrations:
  - sharp-edges.yaml
  - learnings.jsonl
  - DONT_DO.md
---

# Systematic Debugging

**Core principle:** ALWAYS find root cause before attempting fixes. Random fixes waste time and create new bugs.

---

## Sharp Edges Integration

**BEFORE starting debugging, check known gotchas:**

```bash
# Check sharp-edges.yaml for known issues matching error pattern
cat ~/.claude/memory/sharp-edges.yaml

# Check DONT_DO.md for similar past failures
cat .claude/DONT_DO.md
```

If error matches a known sharp edge:
1. Read the documented solution FIRST
2. Apply known fix before investigating further
3. If fix doesn't work, THEN proceed to root cause investigation

---

## Auto-Document to DONT_DO

**After 2+ failed fix attempts:**

```markdown
# Add to .claude/DONT_DO.md:

## YYYY-MM-DD | DEBUGGING

### ❌ [Short description of the bug]

**Context:** What you were trying to do
**Tried:**
1. First approach - result
2. Second approach - result
**Root Cause:** Why the bug occurred
**✅ Solution:** What actually fixed it
**Prevention:** How to avoid in future
```

This prevents repeating the same debugging journey.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes

4. **Gather Evidence in Multi-Component Systems**
   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
   
   Run once to gather evidence
   THEN analyze where it breaks
   ```

5. **Trace Data Flow**
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

1. **Find Working Examples**
   - Locate similar working code in same codebase
   - What works that's similar to what's broken?

2. **Compare Against References**
   - Read reference implementation COMPLETELY
   - Don't skim - understand the pattern fully

3. **Identify Differences**
   - What's different between working and broken?
   - List every difference, however small

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis**
   - State clearly: "I think X is the root cause because Y"
   - Be specific, not vague

2. **Test Minimally**
   - Make SMALLEST possible change to test hypothesis
   - One variable at a time
   - Don't fix multiple things at once

3. **Verify Before Continuing**
   - Did it work? Yes → Phase 4
   - Didn't work? Form NEW hypothesis
   - DON'T add more fixes on top

### Phase 4: Implementation

1. **Create Failing Test Case**
   - Simplest possible reproduction
   - MUST have before fixing

2. **Implement Single Fix**
   - Address root cause identified
   - ONE change at a time
   - No "while I'm here" improvements

3. **Verify Fix**
   - Test passes now?
   - No other tests broken?

4. **If 3+ Fixes Failed: STOP**
   - This indicates architectural problem
   - Don't attempt Fix #4 without discussion
   - Question fundamentals, not symptoms

## Red Flags - STOP and Return to Phase 1

If you catch yourself:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "I don't fully understand but this might work"
- Proposing solutions before tracing data flow

**ALL of these mean: STOP. Return to Phase 1.**

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, trace | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

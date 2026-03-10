---
name: intent-clarifier
description: Use when user request is ambiguous or could have multiple interpretations. Smart clarification to improve one-shot success. Triggers on: unclear, ambiguous, what do you mean, help me understand, clarify.
version: 1.0.0
auto-trigger: true
---

# Intent Clarifier

> Understand deeply before acting. The right question prevents wrong solutions.

---

## When to Use

Activate when you detect:
- Vague requirements ("make it better", "fix the issues")
- Multiple valid interpretations
- Missing critical context
- Potentially expensive operations
- Destructive or irreversible changes

---

## Ambiguity Detection Patterns

| Pattern | Example | Clarification Needed |
|---------|---------|---------------------|
| **Scope Unclear** | "Add authentication" | OAuth? Magic link? Password? Provider? |
| **Target Unclear** | "Fix the bug" | Which bug? What's the symptom? |
| **Quality Undefined** | "Make it faster" | Target latency? Current baseline? |
| **Design Vague** | "Improve the UI" | Which screens? What problems? |
| **Tech Unspecified** | "Add a database" | Postgres? SQLite? Supabase? |

---

## Clarification Framework

### 1. Identify the Ambiguity Type

```yaml
Scope: What exactly needs to be done?
Target: Which files/components/features?
Approach: How should it be implemented?
Constraints: Performance, compatibility, timeline?
Success Criteria: How do we know it's done?
```

### 2. Ask Focused Questions

Instead of asking everything at once, prioritize:

```markdown
## Priority 1 (Blockers)
- Questions that determine the entire approach
- E.g., "Should this be server-side or client-side?"

## Priority 2 (Important)
- Questions that affect implementation significantly
- E.g., "Do you need real-time updates?"

## Priority 3 (Nice to Know)
- Questions about preferences
- E.g., "Any specific naming conventions?"
```

### 3. Offer Structured Choices

```markdown
Bad: "How should I implement this?"

Good: "For the auth system, I recommend:
1. **Clerk** (Recommended) - Fastest setup, great UX
2. **NextAuth** - More customizable, self-hosted
3. **Supabase Auth** - If you're already using Supabase

Which approach works best for your needs?"
```

---

## One-Shot Enhancement Patterns

### Pattern 1: Assumption Declaration

When you CAN make reasonable assumptions:

```markdown
## Understanding

You want to add user authentication to your Next.js app.

## Assumptions (correct me if wrong)
1. Using Clerk (based on your tech stack)
2. Email + Google OAuth login
3. Protecting /dashboard/* routes
4. Middleware-based auth check

## Plan
[Proceed with plan based on assumptions]

Does this match what you need?
```

### Pattern 2: Quick Options

For common decisions:

```markdown
## Quick Decision Needed

**Question:** How should errors be displayed to users?

A) Toast notifications (non-blocking)
B) Inline error messages (form validation)
C) Full-page error (critical failures)
D) All of the above based on severity

*I'll use (D) unless you prefer otherwise.*
```

### Pattern 3: Smart Defaults

State the default, proceed unless stopped:

```markdown
I'll implement this with:
- TypeScript strict mode
- Error boundaries for crash protection
- Loading states for async operations
- Mobile-responsive layout

Proceeding in 5 seconds unless you want changes...
```

---

## Context Gathering Questions

### For Bug Fixes
```markdown
To fix this effectively, I need:
1. What's the expected behavior?
2. What's actually happening?
3. Steps to reproduce?
4. Any error messages?
5. When did it start? (recent changes?)
```

### For New Features
```markdown
To build this right the first time:
1. Who uses this feature? (user type)
2. What's the main user goal?
3. Any similar features to reference?
4. Must-have vs nice-to-have?
5. Any technical constraints?
```

### For Performance Issues
```markdown
To optimize effectively:
1. What's slow? (page load, API, query?)
2. Current metrics? (load time, response time)
3. Target metrics?
4. Traffic volume?
5. Already tried anything?
```

### For Refactoring
```markdown
To refactor safely:
1. What's the pain point?
2. Is this code covered by tests?
3. Any dependent systems?
4. Can we do incremental changes?
5. What's the deadline?
```

---

## Anti-Patterns

❌ **Ask everything at once** - Overwhelming, low response rate
❌ **Open-ended questions** - "How do you want this?" → No direction
❌ **No defaults** - User has to think about everything
❌ **Proceed without understanding** - Waste time on wrong solution
❌ **Assume without stating** - Silent assumptions lead to mismatches

---

## Success Metrics

Good clarification leads to:
- First implementation matches expectations
- No "that's not what I meant" responses
- Reduced back-and-forth iterations
- User feels understood
- Clear success criteria from the start

---

## Integration with Workflow

```
User Request
     ↓
┌─────────────────┐
│ Ambiguity Check │
└─────────────────┘
     ↓
  Ambiguous? ─── No ──→ Proceed with task
     │
    Yes
     ↓
┌─────────────────┐
│ Smart Questions │ (max 3 focused questions)
└─────────────────┘
     ↓
┌─────────────────┐
│ State Assumptions│
└─────────────────┘
     ↓
  Proceed with clear understanding
```

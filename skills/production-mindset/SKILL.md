---
name: production-mindset
description: Use for any code going to production. Ship production-ready code, not prototypes. Always active.
version: 2.0.0
triggers:
  - always_active
integrations:
  - request-classifier
  - socratic-gate
---

# Production Mindset

Transform every prompt into production-ready output. No prototypes. No "good enough." Ship code you're proud of.

---

## Socratic Gate (Complex Tasks)

**When REQUEST TYPE is COMPLEX_BUILD or DESIGN, activate this gate.**

Before writing ANY code for complex tasks:

### Step 1: Ask 3+ Strategic Questions

```
1. USER GOAL
   - What specific outcome does the user need?
   - What problem are they solving?
   - What does "success" look like?

2. INTEGRATION
   - How does this fit with existing code?
   - What patterns does this codebase use?
   - What dependencies are involved?

3. EDGE CASES
   - What inputs could break this?
   - What happens when X fails?
   - How do concurrent operations behave?
```

### Step 2: If User Says "Proceed"

Even with approval, ask 2 more edge-case questions:
- "What should happen if [specific failure scenario]?"
- "How should we handle [concurrent/partial state]?"

### Step 3: Require Explicit Approval

```
✅ Valid approvals:
   - "Yes, proceed with that approach"
   - "Let's go with option 2"
   - "That makes sense, implement it"

❌ Invalid (ask more questions):
   - "Sure" (too vague)
   - "Sounds good" (no specific approval)
   - "Whatever works" (no decision made)
```

### Socratic Gate Rules

1. **Never skip for "simple" tasks** - Users often underestimate complexity
2. **Uncertainty = More questions** - When in doubt, ask
3. **Silence ≠ Approval** - Wait for explicit confirmation
4. **Document decisions** - Track WHY choices were made

---

## Auto-Enhancement

When you receive a simple prompt, automatically expand it to production requirements.

### Task Type Detection

| Detected Task | Auto-Added Requirements |
|---------------|------------------------|
| **auth** | Security (rate limit, CSRF), UX (loading, errors), Edge cases |
| **form** | Validation (client+server), UX (feedback), Accessibility |
| **component** | All 7 states, A11y, Animations, Error boundaries |
| **crud** | Data integrity, Optimistic UI, Authorization |
| **api** | Validation, Auth, Error codes, Rate limiting |
| **page** | SEO, Performance, Loading states |
| **payment** | Stripe security, Idempotency, Webhook handling |

### The 7 States

Every UI component must handle:

1. **Initial** - Before any interaction
2. **Loading** - Fetching data or processing
3. **Empty** - No data to display
4. **Success** - Happy path with data
5. **Error** - Something went wrong
6. **Disabled** - Not interactive
7. **Partial** - Some data loaded/failed

### Production Checklist

Before marking any task complete:

```markdown
[ ] All states handled (not just happy path)
[ ] Errors handled gracefully (user-friendly messages)
[ ] Loading states implemented (no blank screens)
[ ] Empty states helpful (guide user)
[ ] TypeScript strict (no any types)
[ ] Accessible (keyboard, screen reader)
[ ] Responsive (mobile, tablet, desktop)
[ ] Secure (input validation, auth checks)
[ ] Performant (no obvious bottlenecks)
```

## Quality Standards

### Code Quality

```typescript
// ❌ Prototype code
const data = response.data
console.log(data)
return data.map(item => <Item item={item} />)

// ✅ Production code
const { data, error, isLoading } = useQuery(...)

if (isLoading) return <ItemListSkeleton />
if (error) return <ErrorState message="Failed to load items" retry={refetch} />
if (!data?.length) return <EmptyState message="No items yet" action={createItem} />

return (
  <ul role="list" aria-label="Items">
    {data.map(item => (
      <Item key={item.id} item={item} />
    ))}
  </ul>
)
```

### Error Messages

```typescript
// ❌ Unhelpful
throw new Error('Error')

// ✅ Production-ready
throw new AppError(
  'Unable to save changes. Please check your connection and try again.',
  'SAVE_FAILED',
  500
)
```

## Golden Rules

1. **Never ship happy-path-only code** - Production users find every edge case
2. **Errors are features** - Handle them beautifully
3. **Loading states prevent frustration** - Show progress
4. **Empty states guide users** - Don't leave them stranded
5. **Types prevent bugs** - No any, no unknown
6. **Accessibility is required** - Not optional

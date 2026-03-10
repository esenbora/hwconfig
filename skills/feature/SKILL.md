---
name: feature
description: Use when building new functionality, adding features, or implementing requirements. Complete feature development with TDD. Triggers on: feature, build, implement, create, add, new feature, develop, make, functionality.
argument-hint: "<feature-description>"
version: 1.0.0
context: fork
agent: orchestrator
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
  - Task
---


## WORKFLOW PHASES

```
CLASSIFY → SOCRATIC → ANALYZE → DESIGN → IMPLEMENT → TEST → VERIFY → COMMIT
    ↓         ↓          ↓         ↓          ↓        ↓        ↓        ↓
  Type    3+ Qs    Patterns   Plan    Code    TDD   Evidence  Ship
```

---

## PHASE 0: SOCRATIC GATE (MANDATORY)

**Before ANY code, ask 3+ strategic questions:**

### Must-Ask Questions

| Area | Question |
|------|----------|
| **Goal** | What specific outcome does the user need? |
| **Context** | How does this integrate with existing system? |
| **Edge Cases** | What could go wrong? What happens on failure? |
| **Security** | Who should have access? What data is sensitive? |
| **Performance** | Any load/scale requirements? |

### Wait for Explicit Approval

```
✅ Proceed when user confirms:
   - Specific approach chosen
   - Edge cases acknowledged
   - Requirements are clear

❌ Ask more questions if:
   - "Sure" / "Sounds good" (too vague)
   - Requirements are ambiguous
   - Security implications unclear
```

---

## ORCHESTRATION

```yaml
Skills:
  Always:
    - production-mindset      # Ship production-ready code
    - clean-code              # Readable, maintainable
    - type-safety             # TypeScript strict mode
    - error-handling          # Handle all errors gracefully
    - tdd                     # Test-first mindset
    - owasp-api-2023          # API security (BOLA, BFLA, SSRF)
    - accessibility           # WCAG 2.2 AA compliance

  Load Based on Feature:
    - react-19                # If React component work
    - nextjs-deep             # If Next.js routing/server
    - drizzle-2026            # If database changes (modern patterns)
    - tanstack-query-deep     # If data fetching/caching
    - design-differentiation  # If UI/landing page work
    - motion-patterns         # If animation work
    - caching                 # If performance-critical data

Agents:
  Lead: orchestrator          # Coordinates the feature development
  Delegate To:
    - architect               # For technical design decisions
    - frontend                # For UI components
    - backend                 # For server actions, API
    - data                    # For database changes
    - quality                 # For testing and review
    - security                # For security review

Knowledge:
  Read First:
    - DONT_DO.md              # Avoid known mistakes
    - CRITICAL_NOTES.md       # Project patterns to follow
    - progress.txt            # Codebase patterns for consistency

  Update After:
    - progress.txt            # Log feature completion
    - CRITICAL_NOTES.md       # If new patterns established
```

---

## WORKFLOW

```
┌─────────────────────────────────────────────────────────────────────┐
│  CLARIFY → ANALYZE → DESIGN → IMPLEMENT → TEST → VERIFY → SHIP     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: CLARIFY REQUIREMENTS

### Essential Questions

**Before ANY code, understand:**

| Question | Why It Matters |
|----------|----------------|
| What problem does this solve? | Ensures you build the right thing |
| Who uses this feature? | Defines UX requirements |
| What are the acceptance criteria? | Defines "done" |
| What edge cases exist? | Prevents bugs later |
| Any performance requirements? | Affects architecture |
| Security considerations? | Prevents vulnerabilities |

### Create Todo List

```
TodoWrite: Create task breakdown

- [ ] Clarify requirements
- [ ] Analyze codebase for patterns
- [ ] Design technical approach
- [ ] Implement database/types (if needed)
- [ ] Implement backend logic
- [ ] Implement frontend UI
- [ ] Handle edge cases
- [ ] Write tests
- [ ] Run quality checks
- [ ] Self-review
```

---

## PHASE 2: CODEBASE ANALYSIS

### Delegate: Explore Agent

Use Task tool with Explore agent to find:
- Similar features in codebase
- Patterns to follow
- Files to modify
- Integration points

### Document Findings

```markdown
## Codebase Analysis

**Similar Features Found:**
- `path/to/similar.ts` - Pattern: [description]

**Files to Modify:**
- `path/file.ts` - [what changes]

**Files to Create:**
- `path/new-file.ts` - [purpose]

**Integration Points:**
- [How this connects to existing code]

**Patterns to Follow:**
- [From CRITICAL_NOTES.md or codebase]
```

### Read Key Files

**MANDATORY:** Read every file you plan to modify before editing.

---

## PHASE 3: TECHNICAL DESIGN

### Consult: Architect Agent

For significant features, design:

```markdown
## Technical Design

### Data Model
- Schema changes: [Prisma/Drizzle schema]
- Types needed: [TypeScript interfaces]
- Validation: [Zod schemas]

### Backend
- Server actions: [List actions needed]
- API routes: [If any new routes]
- Business logic: [Core operations]

### Frontend
- Components: [List components]
- State management: [Local/Zustand/React Query]
- Routes: [If new pages]

### Security
- Auth requirements: [Who can access]
- Validation: [Input sanitization]
- Rate limiting: [If needed]

### Integration
- Dependencies: [What it relies on]
- Dependents: [What relies on it]
```

### Get Approval (If Complex)

For features touching 5+ files, present design summary and wait for user approval.

---

## PHASE 4: IMPLEMENTATION

### Order of Operations

```
1. Types & Validation
   └── Define interfaces, Zod schemas

2. Database (if needed)
   └── Schema → Migration → Generate

3. Backend Logic
   └── Server actions with auth + validation

4. Frontend Components
   └── UI with all states handled

5. Integration
   └── Wire together, add routes
```

### Implementation Standards

**Server Actions:**
```typescript
'use server'

import { z } from 'zod'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { revalidatePath } from 'next/cache'

const FeatureSchema = z.object({
  name: z.string().min(1).max(100),
  // ... other fields
})

export async function createFeature(input: z.infer<typeof FeatureSchema>) {
  // 1. Auth check
  const { userId } = await auth()
  if (!userId) throw new Error('Unauthorized')

  // 2. Validate input
  const data = FeatureSchema.parse(input)

  // 3. Business logic
  const result = await db.feature.create({
    data: { ...data, userId }
  })

  // 4. Revalidate cache
  revalidatePath('/features')

  return result
}
```

**Frontend Components:**
```typescript
'use client'

import { useState, useTransition } from 'react'
import { createFeature } from '@/app/actions/feature'

export function FeatureForm() {
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(formData: FormData) {
    setError(null)
    startTransition(async () => {
      try {
        await createFeature({
          name: formData.get('name') as string,
        })
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Something went wrong')
      }
    })
  }

  return (
    <form action={handleSubmit}>
      {/* Handle: loading, error, empty, success states */}
      {/* Handle: accessibility, responsive design */}
    </form>
  )
}
```

### Update Todos

Mark each task complete immediately after finishing it.

---

## PHASE 5: TESTING

### Delegate: Quality Agent (TDD)

**Write tests for:**

| Priority | What to Test |
|----------|--------------|
| P0 | Happy path - main functionality |
| P0 | Auth - unauthorized access blocked |
| P1 | Validation - invalid input rejected |
| P1 | Edge cases - boundaries handled |
| P2 | Error handling - failures graceful |

**Test Example:**
```typescript
import { describe, it, expect, vi } from 'vitest'
import { createFeature } from '@/app/actions/feature'

describe('createFeature', () => {
  it('creates feature for authenticated user', async () => {
    // Arrange
    vi.mock('@/lib/auth', () => ({ auth: () => ({ userId: 'user-1' }) }))

    // Act
    const result = await createFeature({ name: 'Test Feature' })

    // Assert
    expect(result.name).toBe('Test Feature')
  })

  it('rejects unauthenticated requests', async () => {
    vi.mock('@/lib/auth', () => ({ auth: () => ({ userId: null }) }))

    await expect(createFeature({ name: 'Test' }))
      .rejects.toThrow('Unauthorized')
  })

  it('validates input', async () => {
    await expect(createFeature({ name: '' }))
      .rejects.toThrow()
  })
})
```

---

## PHASE 6: QUALITY CHECKS

### Self-Review Checklist

```markdown
### Code Quality
- [ ] TypeScript strict (no `any`, no `@ts-ignore`)
- [ ] No console.logs in production code
- [ ] Error handling complete
- [ ] Loading states implemented
- [ ] Empty states handled
- [ ] Error states handled

### Security (Consult: Security Agent) - OWASP API 2023
- [ ] Auth checks on all protected actions (API2)
- [ ] Ownership validation on every resource (API1 - BOLA)
- [ ] Input validation with Zod allowlist (API3 - Mass Assignment)
- [ ] Rate limiting on endpoints (API4)
- [ ] Function-level permission checks (API5 - BFLA)
- [ ] No sensitive data in client
- [ ] No NEXT_PUBLIC_ with secrets
- [ ] URL validation if fetching user URLs (API8 - SSRF)

### UX & Accessibility (WCAG 2.2 AA)
- [ ] Responsive design (mobile-first)
- [ ] Keyboard accessible (Tab, Enter, Escape)
- [ ] Focus indicators visible (2px, 3:1 contrast)
- [ ] Touch targets ≥24px (44px recommended)
- [ ] Screen reader friendly (ARIA labels)
- [ ] Color contrast meets requirements (4.5:1 text)
- [ ] Clear error messages (announced to screen readers)
- [ ] Optimistic updates (if applicable)

### Performance
- [ ] No N+1 queries
- [ ] Appropriate caching
- [ ] Lazy loading (if large components)
```

### Run Automated Checks

```bash
# TypeScript
npx tsc --noEmit

# Lint
npm run lint

# Tests
npm test
```

**All checks must pass before completion.**

---

## PHASE 7: VERIFY & SHIP

### Evidence Required

Before marking complete, provide:

1. **Functionality Evidence** - Show it works (output/screenshot description)
2. **Quality Evidence** - TypeScript and lint pass
3. **Test Evidence** - Tests pass

### Summary Output

```markdown
## Feature Complete: [Name]

### What Was Built
[1-2 sentence description]

### Files Changed
| File | Change |
|------|--------|
| `path/file.ts` | [what changed] |

### How to Test
1. [Step 1]
2. [Step 2]
3. [Expected result]

### Quality Status
- TypeScript: ✅ Passes
- Lint: ✅ Passes
- Tests: ✅ X passing

### Follow-up Tasks (if any)
- [ ] [Future enhancement]
```

### Update Knowledge

```markdown
# progress.txt update:
## YYYY-MM-DD HH:MM - Feature: [name]
- Implemented: [brief description]
- Files: [list]
- **Learnings:** [patterns discovered]
```

---

## RULES

```
1. NEVER edit without reading first
   └── Always read files before modifying

2. FOLLOW existing patterns
   └── Check CRITICAL_NOTES.md and similar code

3. TEST critical paths
   └── At minimum: happy path, auth, validation

4. SHOW evidence before "done"
   └── Prove it works, don't just claim it

5. UPDATE knowledge
   └── Add to CRITICAL_NOTES if new patterns established

6. ONE phase at a time
   └── Complete each phase before moving on
```

---

## QUICK REFERENCE: Feature Checklist

```
□ Requirements clear
□ Similar patterns found
□ Technical design approved (if complex)
□ Database/types implemented
□ Backend with auth + validation
□ Frontend with all states
□ Tests written and passing
□ TypeScript passes
□ Lint passes
□ Self-review complete
□ Evidence provided
□ Knowledge updated
```

---

## MOBILE PLATFORM

When building features for React Native / Expo mobile apps, use these additional considerations.

### Mobile-Specific Skills & Agents

```yaml
Skills:
  Load for Mobile:
    - react-native-deep       # RN patterns
    - expo-deep               # Expo specifics

Agents:
  Lead: mobile-orchestrator   # Coordinates feature
  Delegate To:
    - mobile-rn               # React Native implementation
    - mobile-ui               # Mobile UX
    - mobile-integration      # Push, analytics if needed

Quality Gates:
  Additional:
    - ios-verify
    - android-verify
```

### Mobile Clarification Questions

1. **Platforms?** iOS, Android, or both?
2. **Device features?** Camera, location, notifications?
3. **Offline?** Works offline? Sync strategy?
4. **UI approach?** Same UI or platform-adaptive?

### Platform Differences

| Aspect | iOS | Android |
|--------|-----|---------|
| Navigation | Back swipe | Hardware back button |
| Tab bar | Bottom | Bottom (Material 3) |
| Alerts | Alert.alert | Alert.alert (different style) |
| Date picker | Wheels | Calendar |

### Mobile Implementation Pattern

```typescript
// 1. Hook for data
export function useFeature() {
  const query = useQuery({
    queryKey: ['feature'],
    queryFn: fetchFeature,
  })
  return query
}

// 2. Screen
export default function FeatureScreen() {
  const { data, isLoading, error } = useFeature()

  if (isLoading) return <Loading />
  if (error) return <ErrorView error={error} />

  return (
    <SafeAreaView className="flex-1">
      {/* Feature UI */}
    </SafeAreaView>
  )
}
```

### Mobile Testing

```typescript
import { render, waitFor } from '@testing-library/react-native'

describe('FeatureScreen', () => {
  it('shows loading initially', () => {
    const { getByTestId } = render(<FeatureScreen />)
    expect(getByTestId('loading')).toBeTruthy()
  })

  it('displays data after loading', async () => {
    const { getByText } = render(<FeatureScreen />)
    await waitFor(() => {
      expect(getByText('Expected Text')).toBeTruthy()
    })
  })
})
```

### Device Verification

```bash
# iOS Simulator
npx expo run:ios

# Android Emulator
npx expo run:android

# Physical device
npx expo start --dev-client
```

### Mobile Quality Checklist

```markdown
### UI/UX
- [ ] Safe areas handled
- [ ] Keyboard avoids inputs
- [ ] Loading states visible
- [ ] Error states handled
- [ ] Empty states designed

### Navigation
- [ ] Back button works (iOS + Android)
- [ ] Deep links work
- [ ] State preserved on tab switch

### Performance
- [ ] Lists use FlashList (if large)
- [ ] Images optimized
- [ ] 60fps animations

### Platform-Specific
- [ ] Works on iOS
- [ ] Works on Android
- [ ] Looks native on each platform
```

### Mobile Output Format

```markdown
## Feature Complete: [Name]

**Platforms Tested:**
- [ ] iOS Simulator
- [ ] iOS Device
- [ ] Android Emulator
- [ ] Android Device

**Files Changed:**
- [file]: [what changed]

**How to Test:**
1. Navigate to [screen]
2. [Action]
3. Verify [result]

**Evidence:**
- TypeScript: passes
- Tests: [X] passing
- iOS: works
- Android: works
```

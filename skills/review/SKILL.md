---
name: review
description: Use when reviewing code, checking for issues, or ensuring quality. Code review patterns. Triggers on: review, code review, check code, review my code, look at, feedback.
argument-hint: "<file-or-directory>"
version: 1.0.0
context: fork
agent: quality
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---


## ORCHESTRATION

```yaml
Skills:
  Always:
    - security-first          # Security review priority
    - clean-code              # Code quality standards
    - type-safety             # TypeScript verification
    - production-mindset      # Production-ready code

  Load Based on Code Type:
    - react-deep              # React component review
    - nextjs-deep             # Next.js patterns
    - prisma-deep / drizzle-deep  # Database code
    - security-deep           # Security-focused review

Agents:
  Lead: quality               # Quality agent leads review
  Consult:
    - security                # Security issues
    - frontend                # UI/UX patterns
    - backend                 # API patterns
    - performance             # Performance issues

Knowledge:
  Read First:
    - DONT_DO.md              # Known anti-patterns
    - CRITICAL_NOTES.md       # Project patterns to enforce
    - progress.txt            # Codebase patterns

  Update After:
    - DONT_DO.md              # If new anti-pattern found
    - CRITICAL_NOTES.md       # If pattern should be documented
```

---

## REVIEW DIMENSIONS

```
┌──────────────────────────────────────────────────────────────────┐
│           REVIEW = Correctness + Security + Quality               │
│                                                                   │
│  1. Does it WORK?         (Correctness)                          │
│  2. Is it SECURE?         (Security)                             │
│  3. Is it MAINTAINABLE?   (Quality)                              │
│  4. Does it FOLLOW PATTERNS? (Consistency)                       │
└──────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: GATHER CONTEXT

### Get the Code

```bash
# For a PR
git diff main...HEAD

# For a specific file
git diff HEAD~1 -- path/to/file

# For staged changes
git diff --staged
```

### Understand the Change

| Question | Why |
|----------|-----|
| What does this change do? | Understand intent |
| What's the scope? | Assess risk level |
| What files are affected? | Know review scope |
| Are tests included? | Verify coverage |

---

## PHASE 2: CORRECTNESS REVIEW

### Logic & Functionality

| Check | Look For |
|-------|----------|
| **Purpose** | Does code achieve stated goal? |
| **Logic** | Off-by-one, wrong comparison, missing case |
| **Edge cases** | Null, empty, max, min handling |
| **Race conditions** | Async timing issues |
| **Error handling** | All error paths covered |

### Red Flags

```typescript
// ❌ Missing null check
user.profile.name // What if profile is null?

// ❌ Silent error swallowing
try { ... } catch {} // Never do this

// ❌ Off-by-one
for (i = 0; i <= items.length; i++) // Should be <

// ❌ Assignment instead of comparison
if (status = 'active') // Should be ===

// ❌ Missing await
const data = fetchData() // Missing await
```

---

## PHASE 3: SECURITY REVIEW

### Delegate: Security Agent

**The 12 Security Checks:**

| # | Check | Red Flag |
|---|-------|----------|
| 1 | Auth | Protected route without auth() check |
| 2 | Authorization | No ownership/permission verification |
| 3 | Input validation | User input without Zod validation |
| 4 | SQL injection | String concatenation in queries |
| 5 | XSS | dangerouslySetInnerHTML with user data |
| 6 | Secrets | NEXT_PUBLIC_* with API keys |
| 7 | Data exposure | Returning sensitive fields to client |
| 8 | Rate limiting | Public endpoint without limits |
| 9 | Logging | Passwords/tokens in console.log |
| 10 | Error messages | Internal details exposed |
| 11 | Client-side | Prices/permissions calculated in browser |
| 12 | Direct DB | Frontend accessing database directly |

### Critical Security Patterns

```typescript
// ❌ CRITICAL: Missing auth
export async function POST(req) {
  const data = await req.json()
  await db.create({ data })  // No auth check!
}

// ✅ SECURE: Auth verified
export async function POST(req) {
  const { userId } = await auth()
  if (!userId) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  // ...
}
```

```typescript
// ❌ CRITICAL: SQL injection
db.$queryRaw`SELECT * FROM users WHERE id = ${userId}` // Unsafe!

// ✅ SECURE: Parameterized
db.user.findUnique({ where: { id: userId } })
```

```typescript
// ❌ CRITICAL: Exposed secret
const apiKey = process.env.NEXT_PUBLIC_OPENAI_KEY // Exposed to client!

// ✅ SECURE: Server-only
const apiKey = process.env.OPENAI_KEY // Not exposed
```

---

## PHASE 4: QUALITY REVIEW

### Code Quality

| Check | Standard |
|-------|----------|
| **Types** | No `any`, proper generics, strict mode |
| **Naming** | Clear, descriptive, follows conventions |
| **Structure** | Appropriate abstraction level |
| **DRY** | No unnecessary duplication |
| **Comments** | Complex logic explained |
| **Patterns** | Follows codebase conventions |

### Performance

| Check | Issue |
|-------|-------|
| **Queries** | N+1 queries, missing includes |
| **Bundle** | Large imports (import entire lodash) |
| **Renders** | Missing memoization on expensive ops |
| **Memory** | Event listeners not cleaned up |

### React-Specific

| Check | Standard |
|-------|----------|
| **States** | Loading, error, empty all handled |
| **Keys** | Unique, stable keys in lists |
| **Effects** | Cleanup functions present |
| **Memoization** | useMemo/useCallback where needed |

### Red Flags

```typescript
// ❌ Using 'any'
const data: any = await fetch(...)

// ❌ N+1 query
const posts = await db.post.findMany()
for (const post of posts) {
  const author = await db.user.findUnique({ where: { id: post.authorId } })
}

// ❌ Missing cleanup
useEffect(() => {
  window.addEventListener('resize', handler)
  // No cleanup!
}, [])

// ❌ Index as key
{items.map((item, i) => <Item key={i} />)} // Bad for reordering
```

---

## PHASE 5: PATTERN COMPLIANCE

### Check CRITICAL_NOTES.md

Verify code follows documented patterns for:
- File structure
- Naming conventions
- Error handling approach
- State management patterns
- Testing requirements

### Check DONT_DO.md

Verify code doesn't repeat known mistakes.

---

## PHASE 6: OUTPUT

### Review Format

```markdown
## Code Review: [File/PR/Description]

### Summary
[One paragraph: what this change does and overall assessment]

---

### 🔴 Critical Issues (Must Fix)

**These block approval.**

#### 1. [Issue Title]
**Location:** `file.ts:123`
**Problem:** [What's wrong]
**Risk:** [Security/Bug/Data loss]
**Fix:**
```typescript
// Current (problematic)
...

// Suggested (correct)
...
```

---

### 🟠 Warnings (Should Fix)

**Strong recommendations, should fix before merge.**

#### 1. [Issue Title]
**Location:** `file.ts:45`
**Problem:** [What's wrong]
**Suggestion:** [How to fix]

---

### 🟡 Suggestions (Nice to Have)

**Optional improvements for consideration.**

1. **[Title]** (`file.ts:78`) - [Brief explanation]
2. **[Title]** (`file.ts:92`) - [Brief explanation]

---

### 🟢 Positive Feedback

**Good patterns to encourage:**

- [Good pattern observed]
- [Well-handled edge case]
- [Clean implementation]

---

## Verdict

- [ ] ✅ **APPROVE** - Ready to merge
- [ ] 🔄 **REQUEST CHANGES** - Critical issues must be fixed
- [ ] 💬 **COMMENT** - Non-blocking feedback only

---

### Checklist

#### Correctness
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Error handling complete

#### Security
- [ ] Auth on protected routes
- [ ] Input validated
- [ ] No secrets exposed

#### Quality
- [ ] Types are correct
- [ ] Follows patterns
- [ ] Tests included

#### Performance
- [ ] No N+1 queries
- [ ] No unnecessary renders
- [ ] Bundle impact acceptable
```

---

## REVIEW ETIQUETTE

### DO

- Be specific with file:line references
- Offer solutions, not just problems
- Acknowledge good code
- Ask questions when unclear
- Prioritize feedback (critical vs nice-to-have)
- Use code examples for suggestions

### DON'T

- Be vague ("this is bad")
- Only criticize, no praise
- Nitpick style (let linters handle it)
- Block on personal preferences
- Forget to consider context/constraints
- Make it personal

---

## QUICK REFERENCE: Review Checklist

```
□ Understood the change's purpose
□ Checked correctness (logic, edge cases)
□ Checked security (12 rules)
□ Checked quality (types, patterns)
□ Checked performance (queries, renders)
□ Verified against CRITICAL_NOTES.md
□ Verified against DONT_DO.md
□ Tests included/updated
□ Provided actionable feedback
□ Gave verdict with reasoning
```

---

## MOBILE PLATFORM

### Mobile Review Dimensions

#### 1. Correctness
- Does it work correctly on iOS?
- Does it work correctly on Android?
- Edge cases handled?

#### 2. Security (Mobile-Specific)
- [ ] Tokens in SecureStore (not AsyncStorage)?
- [ ] No sensitive data in logs?
- [ ] No hardcoded secrets?
- [ ] No API keys in code?
- [ ] HTTPS only?
- [ ] Deep links validated?
- [ ] Biometrics properly implemented?
- [ ] No jailbreak/root bypass?

#### 3. Performance
- [ ] FlashList for large lists?
- [ ] Images optimized?
- [ ] Native driver for animations?
- [ ] No memory leaks?
- [ ] No re-render issues?

#### 4. Platform
- [ ] Safe areas handled?
- [ ] Keyboard handling?
- [ ] Back button (Android)?
- [ ] Back swipe (iOS)?
- [ ] Platform-adaptive where needed?

### Mobile-Specific Checks

#### Safe Areas
```typescript
// Bad: Missing safe area
<View style={{ flex: 1 }}>
  <Content />
</View>

// Good: Proper safe area
<SafeAreaView style={{ flex: 1 }}>
  <Content />
</SafeAreaView>
```

#### Keyboard Handling
```typescript
// Bad: Keyboard covers input
<View>
  <TextInput />
</View>

// Good: Keyboard avoids input
<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
>
  <TextInput />
</KeyboardAvoidingView>
```

#### List Performance
```typescript
// Bad: FlatList for large data
<FlatList data={largeData} ... />

// Good: FlashList for large data
<FlashList
  data={largeData}
  estimatedItemSize={50}
  ...
/>
```

#### Android Back Button
```typescript
// Bad: No back button handling
function Screen() {
  return <View />
}

// Good: Handles back button
function Screen() {
  useFocusEffect(
    useCallback(() => {
      const backHandler = BackHandler.addEventListener(
        'hardwareBackPress',
        () => {
          // Handle back
          return true
        }
      )
      return () => backHandler.remove()
    }, [])
  )
}
```

#### Image Optimization
```typescript
// Bad: Unoptimized images
<Image source={{ uri: url }} />

// Good: Optimized with expo-image
<Image
  source={url}
  placeholder={blurhash}
  contentFit="cover"
  transition={200}
/>
```

#### Secure Storage
```typescript
// Bad: Sensitive data in AsyncStorage
await AsyncStorage.setItem('token', token)

// Good: Sensitive data in SecureStore
await SecureStore.setItemAsync('token', token)
```

### Mobile Review Checklist

```markdown
### Platform
- [ ] Works on iOS
- [ ] Works on Android
- [ ] Safe areas handled
- [ ] Back navigation works
- [ ] Keyboard handling correct

### Performance
- [ ] FlashList for large lists
- [ ] Images optimized
- [ ] Native driver for animations
- [ ] No memory leaks
- [ ] No unnecessary re-renders

### UX
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Haptic feedback (where appropriate)
- [ ] Accessibility labels

### Security
- [ ] Secure storage used
- [ ] No secrets in code
- [ ] Input validation
- [ ] Deep links validated
- [ ] HTTPS only
```

### Mobile Review Output

```markdown
## Mobile Code Review: [File/PR]

### Summary
[Overview of changes and platform impact]

### Platform Issues
- iOS: [Issues or None]
- Android: [Issues or None]

### Security Issues
- [Issue or None]

### Performance Issues
- [Issue or None]

### UX Issues
- [Issue or None]

### Suggestions
- [Optional improvements]

**Verdict:** APPROVE / REQUEST_CHANGES
**Test on:** iOS Simulator / Android Emulator / Physical Device
```

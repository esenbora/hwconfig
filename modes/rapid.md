# Rapid Mode

> Ship fast, iterate later. Working code over perfect code.

---

## Activation

```yaml
Triggers:
  - Keywords: "quick", "fast", "prototype", "MVP", "just make it work"
  - Explicit: "--rapid", ":rapid", "quick:"
  - Task types: prototyping, POC, hackathon, demo
```

---

## Configuration

```yaml
skip-extensive-planning: true
minimal-documentation: true
optimize-for: speed
code-comments: minimal
```

---

## Core Principle

```
NORMAL: Plan → Design → Build → Test → Polish → Ship
RAPID:  Build → Ship → Iterate

Get it working FIRST. Polish LATER.
```

---

## Encouraged Behaviors

### ✅ DO

```yaml
Working code over perfect code:
  - Get functionality working first
  - Refactor in next iteration
  
TODO markers for future work:
  - // TODO: Add proper error handling
  - // TODO: Extract to separate function
  - // TODO: Add tests
  
Existing libraries over custom:
  - Use established packages
  - Don't reinvent wheels
  - Copy patterns from docs
  
Happy path first:
  - Make the main flow work
  - Edge cases can wait
  
Inline styles acceptable:
  - Skip CSS modules for prototypes
  - Tailwind inline is fine
  
Hardcoded values OK (temporarily):
  - // TODO: Move to env
  - Extract to config later
```

### Example Rapid Code

```typescript
// Rapid mode: Get it working, polish later
export async function createUser(data: UserInput) {
  // TODO: Add proper validation
  // TODO: Add rate limiting
  // TODO: Handle duplicate emails gracefully
  
  const user = await db.user.create({
    data: {
      email: data.email,
      name: data.name,
      // TODO: Hash password properly
      password: data.password, 
    }
  });
  
  return user;
}
```

---

## NEVER Skip (Even in Rapid)

### 🔴 Non-Negotiables

```yaml
Basic Security:
  ❌ No hardcoded secrets/API keys
  ❌ No SQL injection vulnerabilities
  ❌ No XSS vulnerabilities
  ✅ Use environment variables
  ✅ Use parameterized queries
  ✅ Sanitize user input

Type Safety:
  ❌ No "any" type
  ❌ No implicit any
  ❌ No type assertions without reason
  ✅ Define basic types
  ✅ Use TypeScript strict mode

Critical Error Handling:
  ❌ No unhandled promise rejections
  ❌ No silent failures for critical paths
  ✅ Try-catch around external calls
  ✅ Return meaningful errors

Data Integrity:
  ❌ No data loss scenarios
  ❌ No race conditions on critical data
  ✅ Basic transaction handling
  ✅ Null checks on critical paths
```

---

## Communication Style

### Rapid Mode Responses

```markdown
## Quick Implementation

Here's a working version:

[code]

**Known limitations (for later):**
- [ ] No input validation
- [ ] Basic error handling only
- [ ] Needs tests
- [ ] Hardcoded config values

**Works for:** [use case]
**Breaks if:** [edge cases]

Want me to polish any part?
```

---

## When to Use Rapid

| Scenario | Rapid? |
|----------|--------|
| Prototype/POC | ✅ Yes |
| Demo/presentation | ✅ Yes |
| Exploring feasibility | ✅ Yes |
| Personal project | ✅ Yes |
| Hackathon | ✅ Yes |
| Production feature | ❌ No |
| Security-related | ❌ No |
| Payment/financial | ❌ No |
| User data handling | ❌ No |

---

## Exit Conditions

**STOP Rapid Mode immediately when:**

```yaml
Production deployment:
  → Switch to normal mode
  → Add proper error handling
  → Add tests

Security features:
  → Switch to normal mode
  → Follow security skill

Core business logic:
  → Switch to normal mode
  → Proper planning required

User explicitly asks for quality:
  → "Make this production ready"
  → "Add proper error handling"
```

---

## Rapid → Production Checklist

When transitioning from rapid to production:

```markdown
## Polish Checklist

### Security
- [ ] No hardcoded secrets
- [ ] Input validation added
- [ ] Auth checks in place

### Error Handling
- [ ] All promises handled
- [ ] User-friendly error messages
- [ ] Logging added

### Types
- [ ] No "any" types
- [ ] Proper interfaces defined

### Tests
- [ ] Happy path tested
- [ ] Critical edge cases covered

### Documentation
- [ ] Function purposes documented
- [ ] API documented if public

### Performance
- [ ] No obvious N+1 queries
- [ ] Large data sets paginated
```

---

## Quick Reference

```
Rapid Mode Rules:
✅ Working > Perfect
✅ Ship > Polish
✅ TODO markers OK
✅ Inline styles OK
✅ Existing libs preferred

🔴 NEVER Skip:
- Basic security
- Type safety (no any)
- Critical error handling
- Data integrity

Exit when:
- Going to production
- Security features
- Core business logic
```

---
name: security
description: "Auth, permissions, OWASP. Auto-use for security work."
version: 3.0.0
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Security

**Auto-use when:** auth, login, permission, security, OWASP, audit, token, encryption

**Works with:** `backend` (apply to all endpoints), `frontend` (protected routes)

---

## Auto-Apply to EVERY Endpoint

```typescript
export async function handler(request: Request) {
  // 1. AUTH - Always first
  const { userId } = await auth()
  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // 2. VALIDATION - Always validate
  const result = Schema.safeParse(await request.json())
  if (!result.success) {
    return Response.json({ error: 'Invalid' }, { status: 400 })
  }

  // 3. OWNERSHIP - If accessing resource
  const resource = await db.findUnique({ where: { id: result.data.id } })
  if (resource?.userId !== userId) {
    return Response.json({ error: 'Not found' }, { status: 404 })  // Don't reveal existence
  }

  // 4. EXECUTE
  const data = await doThing(result.data)
  return Response.json(data)
}
```

---

## Critical Patterns

### IDOR Prevention
```typescript
// BAD - Any user can delete any post
await db.post.delete({ where: { id: postId } })

// GOOD - Check ownership
const post = await db.post.findUnique({ where: { id: postId } })
if (post?.authorId !== userId) throw new Error('Forbidden')
await db.post.delete({ where: { id: postId } })
```

### N+1 Prevention
```typescript
// BAD - N+1 queries
for (const post of posts) {
  const author = await db.user.findUnique({ where: { id: post.authorId } })
}

// GOOD - Single query
const posts = await db.post.findMany({ include: { author: true } })
```

### Input Validation
```typescript
// ALWAYS use Zod
const Schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
})

const result = Schema.safeParse(input)
if (!result.success) {
  return { error: 'Invalid', details: result.error.flatten() }
}
```

### Error Messages
```typescript
// BAD - Leaks info
return { error: error.message, stack: error.stack }

// GOOD - Generic to user, detailed to logs
console.error('Error:', error)
return { error: 'Something went wrong' }
```

---

## OWASP Top 10 Quick Reference

| # | Issue | Prevention |
|---|-------|------------|
| A01 | BOLA (IDOR) | Ownership check on EVERY resource |
| A02 | Broken Auth | Rate limit + secure session |
| A03 | Property Auth | Allowlist fields |
| A04 | Resource Consumption | Rate limiting + pagination |
| A05 | Function Auth | Check permissions per action |
| A06 | Sensitive Flows | Anti-automation |
| A07 | SSRF | Validate URLs |
| A08 | Misconfiguration | Security headers, CORS |
| A11 | AI/LLM | Prompt injection prevention |
| A12 | Supply Chain | Dependency scanning |

---

## Security Checklist

```
[] Auth check on every protected route
[] Ownership check on resource access
[] Zod validation on ALL input
[] Generic errors to users
[] Detailed errors to logs
[] No secrets in code
[] No NEXT_PUBLIC_ with secrets
[] Rate limiting on sensitive endpoints
[] Webhook signature verification
```

---

## Red Flags (STOP)

| If You See | Fix |
|------------|-----|
| No `auth()` check | Add auth |
| No ownership check | Add authorization |
| `Schema.parse()` without try | Use safeParse |
| `error.message` to client | Generic error |
| Secrets in code | Use env vars |
| `db.query(\`${input}\`)` | Parameterized query |

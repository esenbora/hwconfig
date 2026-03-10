---
name: auth-security
description: Use when implementing login, signup, sessions, tokens, or any authentication. Security patterns for auth flows. Triggers on: auth security, login security, session, token, jwt, oauth, password, authentication, sign in, sign up, logout.
version: 1.0.0
context: fork
agent: security
detect: ["security-audit"]
---

# Authentication & Authorization Security

Comprehensive auth security patterns and vulnerability detection.

## Authentication Vulnerabilities

### 1. Missing Authentication

```typescript
// ❌ CRITICAL: No auth check
export async function POST(req: Request) {
  const data = await req.json()
  await db.user.update({ where: { id: data.id }, data })
}

// ✅ SECURE: Auth required
export async function POST(req: Request) {
  const { userId } = auth()
  if (!userId) {
    return new Response('Unauthorized', { status: 401 })
  }
  // Only allow updating own data
  await db.user.update({ 
    where: { id: userId }, 
    data: await req.json() 
  })
}
```

### 2. Broken Authorization (IDOR)

```typescript
// ❌ CRITICAL: IDOR vulnerability
export async function GET(req: Request, { params }: { params: { id: string } }) {
  // Any authenticated user can access any record
  const post = await db.post.findUnique({ where: { id: params.id } })
  return Response.json(post)
}

// ✅ SECURE: Ownership check
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const { userId } = auth()
  const post = await db.post.findUnique({ 
    where: { 
      id: params.id,
      authorId: userId // Only return if user owns it
    } 
  })
  
  if (!post) {
    return new Response('Not Found', { status: 404 })
  }
  
  return Response.json(post)
}
```

### 3. Privilege Escalation

```typescript
// ❌ CRITICAL: User can set own role
export async function updateProfile(data: { name: string; role: string }) {
  await db.user.update({
    where: { id: userId },
    data: { name: data.name, role: data.role } // Can escalate to admin!
  })
}

// ✅ SECURE: Role changes require admin
export async function updateProfile(data: { name: string }) {
  // Only allow safe fields
  await db.user.update({
    where: { id: userId },
    data: { name: data.name }
  })
}

// Separate admin-only endpoint for role changes
export async function updateUserRole(targetUserId: string, newRole: string) {
  const { userId } = auth()
  const currentUser = await db.user.findUnique({ where: { id: userId } })
  
  if (currentUser?.role !== 'ADMIN') {
    throw new Error('Forbidden')
  }
  
  await db.user.update({
    where: { id: targetUserId },
    data: { role: newRole }
  })
}
```

## Session Security

### 1. Session Configuration

```typescript
// ✅ Secure session cookies
cookies().set('session', token, {
  httpOnly: true,           // Prevent XSS access
  secure: true,             // HTTPS only
  sameSite: 'lax',          // CSRF protection
  maxAge: 60 * 60 * 24 * 7, // 7 days
  path: '/',
})

// ❌ INSECURE: Missing security flags
cookies().set('session', token) // Defaults are insecure
```

### 2. Session Fixation Prevention

```typescript
// ✅ Regenerate session on login
export async function login(credentials: Credentials) {
  const user = await verifyCredentials(credentials)
  
  // Invalidate old session
  await invalidateSession(cookies().get('session')?.value)
  
  // Create new session
  const newSession = await createSession(user.id)
  cookies().set('session', newSession.token, { /* secure options */ })
  
  return user
}
```

### 3. Session Timeout

```typescript
// ✅ Implement session timeout
const SESSION_TIMEOUT = 30 * 60 * 1000 // 30 minutes

export async function validateSession(token: string) {
  const session = await db.session.findUnique({ where: { token } })
  
  if (!session) return null
  
  // Check if expired
  const lastActivity = new Date(session.lastActivity)
  if (Date.now() - lastActivity.getTime() > SESSION_TIMEOUT) {
    await db.session.delete({ where: { token } })
    return null
  }
  
  // Update last activity
  await db.session.update({
    where: { token },
    data: { lastActivity: new Date() }
  })
  
  return session
}
```

## Password Security

### 1. Password Hashing

```typescript
import bcrypt from 'bcryptjs'

// ✅ Secure password hashing
const SALT_ROUNDS = 12 // Minimum 10, recommended 12+

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS)
}

export async function verifyPassword(
  password: string, 
  hash: string
): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

// ❌ CRITICAL: Weak hashing
import crypto from 'crypto'
const hash = crypto.createHash('md5').update(password).digest('hex') // NEVER!
```

### 2. Password Policy

```typescript
import { z } from 'zod'

// ✅ Strong password requirements
export const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain uppercase letter')
  .regex(/[a-z]/, 'Password must contain lowercase letter')
  .regex(/[0-9]/, 'Password must contain number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain special character')

// Check against common passwords
const COMMON_PASSWORDS = ['password', '123456', 'qwerty', ...]

export function validatePassword(password: string) {
  if (COMMON_PASSWORDS.includes(password.toLowerCase())) {
    throw new Error('Password is too common')
  }
  return passwordSchema.parse(password)
}
```

## Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

// ✅ Rate limit auth endpoints
const authRatelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '15 m'), // 5 attempts per 15 min
  analytics: true,
})

export async function login(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous'
  
  const { success, remaining } = await authRatelimit.limit(`login:${ip}`)
  
  if (!success) {
    return new Response('Too many login attempts. Try again later.', {
      status: 429,
      headers: { 'Retry-After': '900' } // 15 minutes
    })
  }
  
  // Process login...
}
```

## Security Headers

```typescript
// next.config.ts
const securityHeaders = [
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block'
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin'
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()'
  }
]

export default {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ]
  },
}
```

## Audit Checklist

```markdown
## Authentication Audit

### Critical
- [ ] All protected endpoints require authentication
- [ ] Password hashed with bcrypt (12+ rounds) or argon2
- [ ] No credentials in code or logs
- [ ] Session tokens are cryptographically random

### High
- [ ] Authorization checks user ownership/role
- [ ] Rate limiting on auth endpoints
- [ ] Account lockout after failed attempts
- [ ] Session timeout implemented

### Medium
- [ ] Strong password policy enforced
- [ ] MFA available for sensitive accounts
- [ ] Security headers configured
- [ ] CSRF protection enabled

### Low
- [ ] Password breach checking (haveibeenpwned)
- [ ] Login notifications
- [ ] Session management UI for users
```

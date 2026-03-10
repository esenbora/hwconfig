---
name: session-security
description: Use when implementing sessions or cookies. Session binding, CSRF protection. Triggers on: session, cookie, session security, csrf, session binding.
version: 1.0.0
triggers: ["csrf", "session", "cookie", "token", "session fixation", "session binding"]
---

# Session Security (2026)

> Comprehensive session security patterns for Next.js applications.
> **Insecure sessions = account takeover = catastrophic breach.**

---

## 🚨 WHY THIS MATTERS

```
Session vulnerabilities cause:
❌ CSRF attacks (unauthorized actions on behalf of user)
❌ Session hijacking (attacker steals session)
❌ Session fixation (attacker sets victim's session)
❌ Session replay (attacker reuses old session)
```

---

## CSRF Protection

### Server Actions (Built-in Protection)

Next.js Server Actions have built-in CSRF protection via Origin header checking.

```typescript
// app/actions/user.ts
'use server'

import { auth } from '@clerk/nextjs/server'
import { z } from 'zod'

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100),
})

export async function updateProfile(input: z.infer<typeof UpdateProfileSchema>) {
  // Server Actions automatically check Origin header
  // No additional CSRF token needed for Server Actions

  const { userId } = await auth()
  if (!userId) throw new Error('Unauthorized')

  const parsed = UpdateProfileSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: 'Invalid input' }
  }

  // ... update logic
}
```

### API Routes (Manual CSRF Protection)

For traditional API routes, implement CSRF tokens:

```typescript
// lib/csrf.ts
import { cookies } from 'next/headers'
import { randomBytes, createHmac } from 'crypto'

const CSRF_SECRET = process.env.CSRF_SECRET!
const CSRF_COOKIE_NAME = '__csrf'
const CSRF_HEADER_NAME = 'x-csrf-token'

export function generateCsrfToken(): string {
  const token = randomBytes(32).toString('hex')
  const signature = createHmac('sha256', CSRF_SECRET)
    .update(token)
    .digest('hex')
  return `${token}.${signature}`
}

export function validateCsrfToken(token: string): boolean {
  const [value, signature] = token.split('.')
  if (!value || !signature) return false

  const expectedSignature = createHmac('sha256', CSRF_SECRET)
    .update(value)
    .digest('hex')

  // Timing-safe comparison
  return signature.length === expectedSignature.length &&
    timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    )
}

// Set CSRF cookie
export async function setCsrfCookie(): Promise<string> {
  const token = generateCsrfToken()
  const cookieStore = await cookies()

  cookieStore.set(CSRF_COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    path: '/',
    maxAge: 60 * 60,  // 1 hour
  })

  return token
}

// Middleware to validate CSRF
export async function validateCsrf(request: Request): Promise<boolean> {
  const cookieStore = await cookies()
  const cookieToken = cookieStore.get(CSRF_COOKIE_NAME)?.value
  const headerToken = request.headers.get(CSRF_HEADER_NAME)

  if (!cookieToken || !headerToken) return false
  if (cookieToken !== headerToken) return false

  return validateCsrfToken(cookieToken)
}
```

```typescript
// app/api/sensitive/route.ts
import { validateCsrf } from '@/lib/csrf'

export async function POST(request: Request) {
  // Validate CSRF for state-changing operations
  if (!await validateCsrf(request)) {
    return new Response('Invalid CSRF token', { status: 403 })
  }

  // ... process request
}
```

### Client-Side CSRF Token

```typescript
// hooks/useCsrf.ts
import { useEffect, useState } from 'react'

export function useCsrf() {
  const [token, setToken] = useState<string | null>(null)

  useEffect(() => {
    fetch('/api/csrf')
      .then(res => res.json())
      .then(data => setToken(data.token))
  }, [])

  return token
}

// Usage in component
function SensitiveForm() {
  const csrfToken = useCsrf()

  const handleSubmit = async (data: FormData) => {
    await fetch('/api/sensitive', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-csrf-token': csrfToken!,
      },
      body: JSON.stringify(data),
    })
  }

  return <form onSubmit={handleSubmit}>...</form>
}
```

---

## Secure Cookie Configuration

```typescript
// lib/cookies.ts
import { cookies } from 'next/headers'

interface CookieOptions {
  httpOnly?: boolean
  secure?: boolean
  sameSite?: 'strict' | 'lax' | 'none'
  path?: string
  maxAge?: number
  domain?: string
}

const SECURE_DEFAULTS: CookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  path: '/',
}

// Session cookie (browser session only)
export async function setSessionCookie(name: string, value: string) {
  const cookieStore = await cookies()
  cookieStore.set(name, value, {
    ...SECURE_DEFAULTS,
    // No maxAge = session cookie (deleted on browser close)
  })
}

// Persistent cookie (with expiry)
export async function setPersistentCookie(
  name: string,
  value: string,
  maxAge: number = 60 * 60 * 24 * 7  // 1 week default
) {
  const cookieStore = await cookies()
  cookieStore.set(name, value, {
    ...SECURE_DEFAULTS,
    maxAge,
  })
}

// Auth cookie (extra secure)
export async function setAuthCookie(name: string, value: string) {
  const cookieStore = await cookies()
  cookieStore.set(name, value, {
    httpOnly: true,
    secure: true,  // Always secure for auth
    sameSite: 'strict',
    path: '/',
    maxAge: 60 * 60 * 24,  // 24 hours
  })
}
```

### Cookie Security Attributes

| Attribute | Purpose | When to Use |
|-----------|---------|-------------|
| `httpOnly` | Prevent JS access | Always for session/auth |
| `secure` | HTTPS only | Production always |
| `sameSite: strict` | Block cross-site | Sensitive operations |
| `sameSite: lax` | Allow top-level navigation | General cookies |
| `path: /` | Cookie scope | Default |
| `domain` | Subdomain sharing | Only if needed |

---

## Session Binding

Bind sessions to client characteristics to prevent hijacking:

```typescript
// lib/session/binding.ts
import { headers } from 'next/headers'
import { createHash } from 'crypto'

interface SessionBinding {
  fingerprint: string
  userAgent: string
  ip: string
  createdAt: number
}

export async function createSessionBinding(): Promise<SessionBinding> {
  const headersList = await headers()

  const userAgent = headersList.get('user-agent') || ''
  const ip = headersList.get('x-forwarded-for')?.split(',')[0] ||
             headersList.get('x-real-ip') ||
             'unknown'

  // Create fingerprint from stable characteristics
  const fingerprint = createHash('sha256')
    .update(`${userAgent}:${ip}`)
    .digest('hex')

  return {
    fingerprint,
    userAgent,
    ip,
    createdAt: Date.now(),
  }
}

export async function validateSessionBinding(
  stored: SessionBinding
): Promise<{ valid: boolean; reason?: string }> {
  const current = await createSessionBinding()

  // Strict: fingerprint must match
  if (stored.fingerprint !== current.fingerprint) {
    return {
      valid: false,
      reason: 'Session binding mismatch (fingerprint)',
    }
  }

  // Check session age (max 24 hours)
  const maxAge = 24 * 60 * 60 * 1000
  if (Date.now() - stored.createdAt > maxAge) {
    return {
      valid: false,
      reason: 'Session expired',
    }
  }

  return { valid: true }
}
```

### Session Binding Middleware

```typescript
// middleware.ts (session binding check)
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  // Skip for public routes
  if (isPublicRoute(request.nextUrl.pathname)) {
    return NextResponse.next()
  }

  const sessionBinding = request.cookies.get('session_binding')?.value

  if (sessionBinding) {
    const stored = JSON.parse(sessionBinding) as SessionBinding
    const validation = await validateSessionBinding(stored)

    if (!validation.valid) {
      // Clear session and redirect to login
      const response = NextResponse.redirect(new URL('/login', request.url))
      response.cookies.delete('session_binding')
      response.cookies.delete('session_token')
      return response
    }
  }

  return NextResponse.next()
}
```

---

## Session Fixation Prevention

```typescript
// lib/session/regenerate.ts
import { cookies } from 'next/headers'
import { randomBytes } from 'crypto'

// Regenerate session ID after authentication
export async function regenerateSession(userId: string) {
  const cookieStore = await cookies()

  // Delete old session
  const oldSessionId = cookieStore.get('session_id')?.value
  if (oldSessionId) {
    await deleteSessionFromStore(oldSessionId)
  }

  // Generate new session ID
  const newSessionId = randomBytes(32).toString('hex')

  // Create new session in store
  await createSessionInStore(newSessionId, {
    userId,
    createdAt: Date.now(),
    binding: await createSessionBinding(),
  })

  // Set new session cookie
  cookieStore.set('session_id', newSessionId, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    path: '/',
    maxAge: 60 * 60 * 24,  // 24 hours
  })

  return newSessionId
}

// Use after login
export async function handleLogin(credentials: Credentials) {
  const user = await verifyCredentials(credentials)

  if (user) {
    // ALWAYS regenerate session after successful auth
    await regenerateSession(user.id)
    return { success: true }
  }

  return { success: false, error: 'Invalid credentials' }
}
```

---

## Session Timeout & Idle Detection

```typescript
// lib/session/timeout.ts
interface SessionTimeouts {
  absolute: number    // Max session lifetime
  idle: number        // Max time between requests
}

const TIMEOUTS: SessionTimeouts = {
  absolute: 24 * 60 * 60 * 1000,  // 24 hours
  idle: 30 * 60 * 1000,           // 30 minutes
}

export async function validateSessionTimeout(
  session: SessionData
): Promise<{ valid: boolean; reason?: string }> {
  const now = Date.now()

  // Check absolute timeout
  if (now - session.createdAt > TIMEOUTS.absolute) {
    return { valid: false, reason: 'Session expired (absolute timeout)' }
  }

  // Check idle timeout
  if (now - session.lastActivity > TIMEOUTS.idle) {
    return { valid: false, reason: 'Session expired (idle timeout)' }
  }

  return { valid: true }
}

// Update last activity on each request
export async function touchSession(sessionId: string) {
  await updateSessionInStore(sessionId, {
    lastActivity: Date.now(),
  })
}
```

### Client-Side Idle Detection

```typescript
// hooks/useIdleLogout.ts
import { useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'

export function useIdleLogout(timeoutMs: number = 30 * 60 * 1000) {
  const router = useRouter()
  const timeoutRef = useRef<NodeJS.Timeout>()

  useEffect(() => {
    const resetTimer = () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current)

      timeoutRef.current = setTimeout(() => {
        // Log out user due to inactivity
        fetch('/api/auth/logout', { method: 'POST' })
          .then(() => router.push('/login?reason=idle'))
      }, timeoutMs)
    }

    // Reset on any activity
    const events = ['mousedown', 'keydown', 'touchstart', 'scroll']
    events.forEach(event => window.addEventListener(event, resetTimer))

    resetTimer()  // Start timer

    return () => {
      events.forEach(event => window.removeEventListener(event, resetTimer))
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
    }
  }, [timeoutMs, router])
}
```

---

## Concurrent Session Control

```typescript
// lib/session/concurrent.ts
const MAX_CONCURRENT_SESSIONS = 3

export async function enforceConcurrentSessionLimit(userId: string) {
  const activeSessions = await getActiveSessionsForUser(userId)

  if (activeSessions.length >= MAX_CONCURRENT_SESSIONS) {
    // Option 1: Reject new login
    // throw new Error('Maximum sessions reached')

    // Option 2: Invalidate oldest session (recommended)
    const oldest = activeSessions.sort((a, b) => a.createdAt - b.createdAt)[0]
    await invalidateSession(oldest.id)
  }
}

// Call during login
export async function handleLogin(credentials: Credentials) {
  const user = await verifyCredentials(credentials)

  if (user) {
    await enforceConcurrentSessionLimit(user.id)
    await regenerateSession(user.id)
    return { success: true }
  }

  return { success: false }
}
```

---

## Security Headers for Sessions

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const response = NextResponse.next()

  // Prevent session exposure via XSS
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-XSS-Protection', '1; mode=block')

  // Prevent session leakage via referrer
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')

  // Content Security Policy
  response.headers.set('Content-Security-Policy', [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "frame-ancestors 'none'",
  ].join('; '))

  return response
}
```

---

## Security Checklist

```
CSRF Protection:
□ Server Actions used (built-in CSRF)
□ API routes have CSRF tokens
□ CSRF tokens validated on state-changing requests
□ SameSite cookie attribute set

Cookie Security:
□ httpOnly on all session cookies
□ secure flag in production
□ sameSite: strict for auth cookies
□ Appropriate maxAge set

Session Binding:
□ Session bound to client fingerprint
□ Session binding validated on each request
□ Binding mismatch invalidates session

Session Fixation:
□ Session regenerated after login
□ Old session invalidated on regeneration
□ New session ID is cryptographically random

Timeouts:
□ Absolute session timeout (24h max)
□ Idle timeout (30min recommended)
□ Client-side idle detection
□ Concurrent session limits

Headers:
□ X-Frame-Options: DENY
□ X-Content-Type-Options: nosniff
□ Referrer-Policy set
□ CSP configured
```

---

## Anti-Patterns

```typescript
// ❌ WRONG: Cookie without httpOnly
cookies().set('session', token, { secure: true })  // JS can steal!

// ❌ WRONG: No CSRF on API route
export async function POST(req: Request) {
  const data = await req.json()  // No CSRF check!
  await updateUser(data)
}

// ❌ WRONG: No session regeneration after login
async function login(credentials) {
  const user = await verify(credentials)
  // Session ID stays same = session fixation!
}

// ❌ WRONG: No session binding
const session = await getSession(sessionId)  // No binding check!

// ✅ CORRECT: Full security
cookies().set('session', token, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 60 * 60 * 24,
})
```

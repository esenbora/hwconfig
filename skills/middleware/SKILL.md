---
name: middleware
description: Use when adding Next.js middleware. Auth checks, redirects, headers, geo-blocking. Triggers on: middleware, next middleware, edge, redirect, rewrite, headers, geo, matcher.
version: 1.0.0
---

# Middleware (2026)

> **Priority:** CRITICAL | **Auto-Load:** On middleware, route protection work
> **Triggers:** middleware, route guard, auth middleware, protected route

---

## ⚠️ CRITICAL SECURITY WARNING: CVE-2025-29927

**Middleware-only authentication is UNSAFE and can be bypassed!**

The CVE-2025-29927 (CVSS 9.1) vulnerability demonstrated that middleware-based auth can be bypassed with a single HTTP header (`x-middleware-subrequest`).

### What This Means

```
❌ UNSAFE: Middleware alone protects routes
✅ SAFE: Middleware + DAL (Data Access Layer) verification
```

**Required Next.js versions:** 15.2.3+, 14.2.25+, 13.5.9+, 12.3.5+

### The New Security Model

```
OLD (Vulnerable):
  Request → Middleware (auth) → Route Handler → Database
                   ↑
            Could be bypassed!

NEW (Secure):
  Request → Middleware (auth) → Route Handler → DAL (auth) → Database
                                                    ↑
                                          Independent verification!
```

---

## Middleware Purpose (2026)

Middleware is now for **optimization and UX**, NOT sole security:

| Use Middleware For | Do NOT Rely On Middleware For |
|--------------------|-------------------------------|
| Redirect unauthenticated users to login | Protecting sensitive data |
| Add headers (CORS, security) | Sole authorization check |
| Logging and analytics | Blocking unauthorized access |
| A/B testing | Role-based access control |
| Geo-based routing | Subscription/plan verification |
| Bot detection | |

---

## Basic Setup

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Add security headers to all responses
  const response = NextResponse.next()

  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  response.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()'
  )

  return response
}

export const config = {
  matcher: [
    // Match all paths except static files
    '/((?!_next/static|_next/image|favicon.ico|public).*)',
  ],
}
```

---

## Auth Middleware (Redirect Only)

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
// Or: import { getToken } from 'next-auth/jwt'

// Define route types
const publicRoutes = ['/', '/sign-in', '/sign-up', '/api/webhook']
const authRoutes = ['/sign-in', '/sign-up']

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Get session (Clerk example)
  const { userId } = await auth()

  // NextAuth example:
  // const token = await getToken({ req: request })
  // const isAuthenticated = !!token

  const isAuthenticated = !!userId
  const isPublicRoute = publicRoutes.includes(pathname)
  const isAuthRoute = authRoutes.includes(pathname)

  // Redirect authenticated users away from auth pages
  if (isAuthRoute && isAuthenticated) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // Redirect unauthenticated users to sign-in (UX only!)
  // ⚠️ This is NOT security - DAL must verify independently
  if (!isPublicRoute && !isAuthenticated) {
    const signInUrl = new URL('/sign-in', request.url)
    signInUrl.searchParams.set('callbackUrl', pathname)
    return NextResponse.redirect(signInUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\..*).*)'],
}
```

---

## Role-Based Redirect (UX Only)

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'

const adminRoutes = ['/admin', '/admin/users', '/admin/settings']
const moderatorRoutes = ['/moderate', '/reports']

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const { userId, sessionClaims } = await auth()

  if (!userId) {
    return NextResponse.redirect(new URL('/sign-in', request.url))
  }

  const role = sessionClaims?.role as string | undefined

  // UX redirect - NOT security!
  // ⚠️ Actual data access must verify role in DAL
  if (adminRoutes.some(route => pathname.startsWith(route))) {
    if (role !== 'admin') {
      return NextResponse.redirect(new URL('/unauthorized', request.url))
    }
  }

  if (moderatorRoutes.some(route => pathname.startsWith(route))) {
    if (!['admin', 'moderator'].includes(role ?? '')) {
      return NextResponse.redirect(new URL('/unauthorized', request.url))
    }
  }

  return NextResponse.next()
}
```

---

## Rate Limiting in Middleware (Edge)

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '1 m'),
  analytics: true,
})

export async function middleware(request: NextRequest) {
  // Only rate limit API routes
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next()
  }

  // Get identifier
  const ip = request.ip ?? request.headers.get('x-forwarded-for') ?? 'anonymous'

  const { success, limit, remaining, reset } = await ratelimit.limit(ip)

  if (!success) {
    return NextResponse.json(
      { error: 'Too many requests' },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': reset.toString(),
          'Retry-After': Math.ceil((reset - Date.now()) / 1000).toString(),
        },
      }
    )
  }

  const response = NextResponse.next()
  response.headers.set('X-RateLimit-Limit', limit.toString())
  response.headers.set('X-RateLimit-Remaining', remaining.toString())

  return response
}
```

---

## Geo-Based Routing

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const country = request.geo?.country || 'US'
  const city = request.geo?.city || 'Unknown'

  // Block restricted countries
  const blockedCountries = ['XX', 'YY']
  if (blockedCountries.includes(country)) {
    return NextResponse.rewrite(new URL('/blocked', request.url))
  }

  // Regional routing
  if (country === 'DE' || country === 'AT' || country === 'CH') {
    // Redirect to German version
    if (!request.nextUrl.pathname.startsWith('/de')) {
      return NextResponse.redirect(new URL(`/de${request.nextUrl.pathname}`, request.url))
    }
  }

  // Add geo headers for downstream use
  const response = NextResponse.next()
  response.headers.set('X-User-Country', country)
  response.headers.set('X-User-City', city)

  return response
}
```

---

## A/B Testing

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const response = NextResponse.next()

  // Check for existing bucket
  let bucket = request.cookies.get('ab-bucket')?.value

  if (!bucket) {
    // Assign new bucket (50/50 split)
    bucket = Math.random() < 0.5 ? 'control' : 'variant'
    response.cookies.set('ab-bucket', bucket, {
      maxAge: 60 * 60 * 24 * 30, // 30 days
      httpOnly: true,
    })
  }

  // Add bucket to headers for server components
  response.headers.set('X-AB-Bucket', bucket)

  // Rewrite to variant page
  if (bucket === 'variant' && request.nextUrl.pathname === '/pricing') {
    return NextResponse.rewrite(new URL('/pricing-variant', request.url))
  }

  return response
}
```

---

## Bot Detection

```typescript
// middleware.ts
const BOT_PATTERNS = [
  /bot/i,
  /crawler/i,
  /spider/i,
  /scraper/i,
  /curl/i,
  /wget/i,
  /python-requests/i,
]

export function middleware(request: NextRequest) {
  const userAgent = request.headers.get('user-agent') || ''

  const isBot = BOT_PATTERNS.some(pattern => pattern.test(userAgent))

  if (isBot) {
    // Option 1: Block bots
    // return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Option 2: Serve different content
    return NextResponse.rewrite(new URL('/static-version', request.url))

    // Option 3: Log and continue
    // console.log('Bot detected:', userAgent)
  }

  return NextResponse.next()
}
```

---

## Security Headers Middleware

```typescript
// middleware.ts
const securityHeaders = {
  'X-DNS-Prefetch-Control': 'on',
  'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
  'X-Frame-Options': 'SAMEORIGIN',
  'X-Content-Type-Options': 'nosniff',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
}

// CSP for production
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline' https://va.vercel-scripts.com;
  style-src 'self' 'unsafe-inline';
  img-src 'self' blob: data: https:;
  font-src 'self';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;
`.replace(/\s{2,}/g, ' ').trim()

export function middleware(request: NextRequest) {
  const response = NextResponse.next()

  // Add security headers
  Object.entries(securityHeaders).forEach(([key, value]) => {
    response.headers.set(key, value)
  })

  // Add CSP in production
  if (process.env.NODE_ENV === 'production') {
    response.headers.set('Content-Security-Policy', ContentSecurityPolicy)
  }

  return response
}
```

---

## Chaining Multiple Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest, NextMiddleware } from 'next/server'

type MiddlewareFactory = (middleware: NextMiddleware) => NextMiddleware

function chain(functions: MiddlewareFactory[], index = 0): NextMiddleware {
  const current = functions[index]

  if (current) {
    const next = chain(functions, index + 1)
    return current(next)
  }

  return () => NextResponse.next()
}

// Individual middlewares
const withLogging: MiddlewareFactory = (next) => {
  return async (request) => {
    console.log('Request:', request.method, request.url)
    return next(request)
  }
}

const withHeaders: MiddlewareFactory = (next) => {
  return async (request) => {
    const response = await next(request)
    response.headers.set('X-Custom-Header', 'value')
    return response
  }
}

const withAuth: MiddlewareFactory = (next) => {
  return async (request) => {
    const token = request.cookies.get('token')
    if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
      return NextResponse.redirect(new URL('/sign-in', request.url))
    }
    return next(request)
  }
}

// Chain them together
export default chain([withLogging, withAuth, withHeaders])
```

---

## Matcher Patterns

```typescript
export const config = {
  matcher: [
    // Match all paths except static files and api
    '/((?!api|_next/static|_next/image|favicon.ico).*)',

    // Match specific paths
    '/dashboard/:path*',
    '/admin/:path*',

    // Match API routes
    '/api/:path*',

    // Exclude specific paths
    '/((?!api/health|api/webhook).*)',
  ],
}

// Programmatic matching in middleware
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Skip for static files
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/static') ||
    pathname.includes('.')
  ) {
    return NextResponse.next()
  }

  // Continue with middleware logic...
}
```

---

## Edge Runtime Considerations

```typescript
// middleware.ts runs on Edge Runtime
// Limitations:
// - No Node.js APIs (fs, path, etc.)
// - No database connections (use REST APIs)
// - Limited crypto APIs
// - 1MB code size limit
// - 25ms CPU time soft limit

// ✅ Works on Edge
import { Redis } from '@upstash/redis'     // REST-based
import { jwtVerify } from 'jose'            // Edge-compatible JWT

// ❌ Does NOT work on Edge
// import { PrismaClient } from '@prisma/client'  // Node.js only
// import fs from 'fs'                             // Node.js only
// import bcrypt from 'bcrypt'                     // Native module
```

---

## Best Practices

### Do
```
✅ Use middleware for UX improvements (redirects, headers)
✅ Implement rate limiting at edge
✅ Add security headers
✅ Do lightweight operations only
✅ Use REST-based services (Upstash, PlanetScale HTTP)
✅ Keep middleware fast (<25ms)
```

### Don't
```
❌ Rely solely on middleware for auth/authz
❌ Make heavy database queries
❌ Use middleware as security boundary
❌ Trust that middleware will always run
❌ Store sensitive logic in middleware
```

---

## Checklist

```markdown
Security:
[ ] Middleware is NOT sole auth layer
[ ] DAL verifies auth independently
[ ] Using Next.js 15.2.3+ / 14.2.25+
[ ] Security headers configured
[ ] Rate limiting on API routes

Performance:
[ ] Middleware completes <25ms
[ ] Using edge-compatible libraries
[ ] Matcher excludes static files
[ ] No heavy computations

Configuration:
[ ] Matcher patterns correct
[ ] Environment-specific CSP
[ ] Proper cookie settings
```

---

## Related Skills

- `server-actions` - DAL pattern for secure data access
- `rate-limiting` - Upstash rate limiting patterns
- `clerk` / `nextauth` - Auth provider integration
- `security-first` - Security principles

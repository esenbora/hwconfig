---
name: rate-limiting
description: Use when protecting APIs from abuse or overuse. Token bucket, sliding window, Redis-based limits. Triggers on: rate limit, throttle, too many requests, 429, abuse, ddos, limit requests.
version: 1.0.0
---

# Rate Limiting

> **Priority:** CRITICAL | **Auto-Load:** On API, auth, expensive operations
> **Triggers:** rate limit, ratelimit, throttle, abuse prevention

---

## Overview

Rate limiting prevents abuse, protects resources, and ensures fair usage. Essential for:
- Authentication endpoints (prevent brute force)
- API endpoints (prevent abuse)
- Expensive operations (AI, email, payments)
- Public endpoints (prevent scraping)

---

## Upstash Ratelimit (Recommended for Serverless)

### Setup

```typescript
// lib/ratelimit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

// General API rate limit
export const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(100, '1 m'), // 100 req/min
  analytics: true,
  prefix: 'ratelimit:api',
})

// Strict limit for auth
export const authRatelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(5, '15 m'), // 5 attempts per 15 min
  analytics: true,
  prefix: 'ratelimit:auth',
})

// Expensive operations
export const expensiveRatelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '1 h'), // 10 per hour
  analytics: true,
  prefix: 'ratelimit:expensive',
})
```

### Algorithms

```typescript
import { Ratelimit } from '@upstash/ratelimit'

// Fixed Window - Simple, resets at interval boundary
Ratelimit.fixedWindow(10, '10 s') // 10 requests per 10 seconds

// Sliding Window - Smoother, more accurate (recommended)
Ratelimit.slidingWindow(10, '10 s') // 10 requests per 10 seconds

// Token Bucket - Allows bursts, refills over time
Ratelimit.tokenBucket(10, '10 s', 5) // 10 tokens, refill 1 per 10s, max burst 5
```

### Usage in Server Actions

```typescript
'use server'

import { ratelimit, authRatelimit } from '@/lib/ratelimit'
import { auth } from '@clerk/nextjs/server'
import { headers } from 'next/headers'

// Get identifier (user ID or IP)
async function getIdentifier(): Promise<string> {
  const { userId } = await auth()
  if (userId) return userId

  const headersList = headers()
  const forwarded = headersList.get('x-forwarded-for')
  const ip = forwarded?.split(',')[0] ?? 'anonymous'
  return ip
}

export async function createProject(data: ProjectInput) {
  const identifier = await getIdentifier()

  const { success, limit, remaining, reset } = await ratelimit.limit(identifier)

  if (!success) {
    return {
      success: false,
      error: 'Too many requests. Please try again later.',
      retryAfter: Math.ceil((reset - Date.now()) / 1000),
    }
  }

  // Continue with action...
}
```

### Usage in API Routes

```typescript
// app/api/projects/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { ratelimit } from '@/lib/ratelimit'

export async function POST(request: NextRequest) {
  const ip = request.ip ?? request.headers.get('x-forwarded-for') ?? 'anonymous'

  const { success, limit, remaining, reset } = await ratelimit.limit(ip)

  if (!success) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
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

  // Continue with handler...
}
```

### Middleware Rate Limiting (Edge)

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

  const ip = request.ip ?? 'anonymous'
  const { success, limit, remaining, reset } = await ratelimit.limit(ip)

  const response = success
    ? NextResponse.next()
    : NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      )

  response.headers.set('X-RateLimit-Limit', limit.toString())
  response.headers.set('X-RateLimit-Remaining', remaining.toString())
  response.headers.set('X-RateLimit-Reset', reset.toString())

  return response
}

export const config = {
  matcher: '/api/:path*',
}
```

---

## Rate Limit Tiers

### By Endpoint Type

| Endpoint | Limit | Window | Identifier |
|----------|-------|--------|------------|
| Auth (login/signup) | 5 | 15 min | IP |
| Password reset | 3 | 1 hour | IP + Email |
| API (authenticated) | 100 | 1 min | User ID |
| API (public) | 20 | 1 min | IP |
| AI/expensive | 10 | 1 hour | User ID |
| Webhooks | 1000 | 1 min | IP |
| File upload | 10 | 1 hour | User ID |

### By User Plan

```typescript
// lib/ratelimit.ts
export function getRateLimiter(plan: 'free' | 'pro' | 'enterprise') {
  const limits = {
    free: Ratelimit.slidingWindow(100, '1 h'),
    pro: Ratelimit.slidingWindow(1000, '1 h'),
    enterprise: Ratelimit.slidingWindow(10000, '1 h'),
  }

  return new Ratelimit({
    redis,
    limiter: limits[plan],
    prefix: `ratelimit:api:${plan}`,
  })
}

// Usage
const user = await getUser()
const limiter = getRateLimiter(user.plan)
const { success } = await limiter.limit(user.id)
```

---

## Multi-Region Setup

```typescript
// For globally distributed apps
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis1 = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL_US!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN_US!,
})

const redis2 = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL_EU!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN_EU!,
})

export const ratelimit = new Ratelimit({
  redis: [redis1, redis2], // Multi-region
  limiter: Ratelimit.slidingWindow(100, '1 m'),
})
```

---

## Response Headers

Always include rate limit headers:

```typescript
const headers = {
  'X-RateLimit-Limit': limit.toString(),        // Max requests
  'X-RateLimit-Remaining': remaining.toString(), // Remaining
  'X-RateLimit-Reset': reset.toString(),         // Reset timestamp
  'Retry-After': retryAfter.toString(),          // Seconds to wait (on 429)
}
```

---

## Client-Side Handling

```typescript
// lib/api.ts
export async function fetchWithRetry(url: string, options?: RequestInit) {
  const response = await fetch(url, options)

  if (response.status === 429) {
    const retryAfter = response.headers.get('Retry-After')
    const waitTime = retryAfter ? parseInt(retryAfter) * 1000 : 60000

    // Show user feedback
    toast.error(`Too many requests. Retry in ${Math.ceil(waitTime / 1000)}s`)

    // Optional: Auto-retry
    await new Promise(resolve => setTimeout(resolve, waitTime))
    return fetchWithRetry(url, options)
  }

  return response
}
```

---

## Best Practices

### Identifier Selection

```typescript
// Best practice: User ID > API Key > IP
function getIdentifier(request: NextRequest, userId?: string): string {
  // Authenticated users - use user ID
  if (userId) return `user:${userId}`

  // API key - use key hash
  const apiKey = request.headers.get('x-api-key')
  if (apiKey) return `key:${hashApiKey(apiKey)}`

  // Fallback to IP
  const forwarded = request.headers.get('x-forwarded-for')
  const ip = forwarded?.split(',')[0] ?? request.ip ?? 'anonymous'
  return `ip:${ip}`
}
```

### Graceful Degradation

```typescript
export async function safeRateLimit(identifier: string) {
  try {
    return await ratelimit.limit(identifier)
  } catch (error) {
    // Redis down - allow request but log
    console.error('Rate limit check failed:', error)
    return { success: true, limit: 0, remaining: 0, reset: 0 }
  }
}
```

---

## Checklist

```markdown
[ ] Rate limiting on all public endpoints
[ ] Strict limits on auth endpoints (5/15min)
[ ] User ID as identifier for authenticated requests
[ ] Proper 429 response with headers
[ ] Retry-After header on rate limit
[ ] Different limits by endpoint criticality
[ ] Different limits by user plan (if applicable)
[ ] Graceful fallback if Redis unavailable
[ ] Client-side retry handling
[ ] Monitoring/analytics enabled
```

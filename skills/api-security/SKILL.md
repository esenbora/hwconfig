---
name: api-security
description: Use when building APIs, endpoints, or handling requests. Rate limiting, CORS, authentication headers, API keys. Triggers on: api security, rate limit, cors, api key, endpoint security, headers, authorization header.
version: 1.0.0
context: fork
agent: security
detect: ["security-audit"]
---

# API Security

Comprehensive API security patterns and vulnerability prevention.

## Rate Limiting

### Implementation

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

// Different limits for different endpoints
const rateLimiters = {
  // Strict for auth endpoints
  auth: new Ratelimit({
    redis: Redis.fromEnv(),
    limiter: Ratelimit.slidingWindow(5, '15 m'),
    prefix: 'ratelimit:auth',
  }),
  
  // Standard for API endpoints
  api: new Ratelimit({
    redis: Redis.fromEnv(),
    limiter: Ratelimit.slidingWindow(100, '1 m'),
    prefix: 'ratelimit:api',
  }),
  
  // Very strict for sensitive operations
  sensitive: new Ratelimit({
    redis: Redis.fromEnv(),
    limiter: Ratelimit.slidingWindow(3, '1 h'),
    prefix: 'ratelimit:sensitive',
  }),
}

// ✅ Rate limit middleware
export async function withRateLimit(
  req: Request,
  type: keyof typeof rateLimiters = 'api'
) {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous'
  const { success, limit, remaining, reset } = await rateLimiters[type].limit(ip)

  const headers = {
    'X-RateLimit-Limit': limit.toString(),
    'X-RateLimit-Remaining': remaining.toString(),
    'X-RateLimit-Reset': reset.toString(),
  }

  if (!success) {
    return new Response('Too Many Requests', {
      status: 429,
      headers: {
        ...headers,
        'Retry-After': Math.ceil((reset - Date.now()) / 1000).toString(),
      },
    })
  }

  return { headers }
}

// Usage
export async function POST(req: Request) {
  const rateLimitResult = await withRateLimit(req, 'api')
  if (rateLimitResult instanceof Response) {
    return rateLimitResult
  }

  // Process request...
  return Response.json(data, { headers: rateLimitResult.headers })
}
```

### User-Based Rate Limiting

```typescript
// ✅ Rate limit by user ID for authenticated endpoints
export async function POST(req: Request) {
  const { userId } = auth()
  if (!userId) {
    return new Response('Unauthorized', { status: 401 })
  }

  const { success } = await rateLimiter.limit(`user:${userId}`)
  if (!success) {
    return new Response('Rate limit exceeded', { status: 429 })
  }

  // Process request...
}
```

## CORS Configuration

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Open CORS
export async function GET(req: Request) {
  return Response.json(data, {
    headers: {
      'Access-Control-Allow-Origin': '*', // Anyone can access!
      'Access-Control-Allow-Credentials': 'true', // VERY DANGEROUS with *
    }
  })
}

// ❌ HIGH: Dynamic origin without validation
const origin = req.headers.get('origin')
return Response.json(data, {
  headers: {
    'Access-Control-Allow-Origin': origin, // Reflects any origin!
  }
})
```

### Secure CORS

```typescript
// ✅ SECURE: Whitelist allowed origins
const ALLOWED_ORIGINS = [
  'https://yourdomain.com',
  'https://app.yourdomain.com',
  process.env.NODE_ENV === 'development' && 'http://localhost:3000',
].filter(Boolean) as string[]

export async function OPTIONS(req: Request) {
  const origin = req.headers.get('origin')
  
  if (!origin || !ALLOWED_ORIGINS.includes(origin)) {
    return new Response(null, { status: 403 })
  }

  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Max-Age': '86400',
    }
  })
}

// ✅ Next.js config
// next.config.ts
module.exports = {
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: 'https://yourdomain.com' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,DELETE,OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type, Authorization' },
        ]
      }
    ]
  }
}
```

## API Authentication

### API Key Validation

```typescript
// ✅ Secure API key validation
export async function validateApiKey(req: Request) {
  const apiKey = req.headers.get('x-api-key')
  
  if (!apiKey) {
    return { valid: false, error: 'Missing API key' }
  }

  // Hash the API key for comparison (store hashed keys in DB)
  const hashedKey = crypto
    .createHash('sha256')
    .update(apiKey)
    .digest('hex')

  const keyRecord = await db.apiKey.findUnique({
    where: { hashedKey },
    include: { user: true }
  })

  if (!keyRecord) {
    return { valid: false, error: 'Invalid API key' }
  }

  if (keyRecord.expiresAt && keyRecord.expiresAt < new Date()) {
    return { valid: false, error: 'API key expired' }
  }

  // Update last used
  await db.apiKey.update({
    where: { id: keyRecord.id },
    data: { lastUsedAt: new Date() }
  })

  return { valid: true, user: keyRecord.user, scopes: keyRecord.scopes }
}
```

### JWT Validation

```typescript
import jwt from 'jsonwebtoken'

// ✅ Secure JWT validation
export function validateJWT(token: string) {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!, {
      algorithms: ['HS256'], // Explicitly specify algorithm
      issuer: 'your-app',
      audience: 'your-api',
    })
    
    return { valid: true, payload: decoded }
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return { valid: false, error: 'Token expired' }
    }
    if (error instanceof jwt.JsonWebTokenError) {
      return { valid: false, error: 'Invalid token' }
    }
    return { valid: false, error: 'Token validation failed' }
  }
}

// ❌ CRITICAL: Don't do this
jwt.verify(token, secret) // Missing algorithm specification - vulnerable to alg:none attack
```

## Input Validation

```typescript
import { z } from 'zod'

// ✅ Define strict schemas for all API inputs
const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(50000),
  tags: z.array(z.string().max(50)).max(10).optional(),
})

export async function POST(req: Request) {
  let body
  try {
    body = await req.json()
  } catch {
    return Response.json({ error: 'Invalid JSON' }, { status: 400 })
  }

  const result = createPostSchema.safeParse(body)
  if (!result.success) {
    return Response.json(
      { error: 'Validation failed', details: result.error.flatten() },
      { status: 400 }
    )
  }

  // Use validated data
  const post = await createPost(result.data)
  return Response.json(post, { status: 201 })
}
```

## Error Handling

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Leaking internal errors
export async function POST(req: Request) {
  try {
    await doSomething()
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 })
    // Exposes: "ECONNREFUSED 127.0.0.1:5432" - reveals DB server
  }
}

// ❌ HIGH: Stack traces in production
return Response.json({ error: error.stack }, { status: 500 })
```

### Secure Error Handling

```typescript
// ✅ SECURE: Generic errors to client, details to logs
export async function POST(req: Request) {
  try {
    await doSomething()
  } catch (error) {
    // Log full error internally
    console.error('API Error:', {
      endpoint: '/api/posts',
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
      requestId: req.headers.get('x-request-id'),
    })

    // Return generic error to client
    return Response.json(
      { 
        error: 'Internal server error',
        requestId: req.headers.get('x-request-id') // For support tickets
      },
      { status: 500 }
    )
  }
}

// ✅ Custom error classes for different scenarios
class APIError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public code: string = 'INTERNAL_ERROR'
  ) {
    super(message)
  }
}

class ValidationError extends APIError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR')
  }
}

class AuthenticationError extends APIError {
  constructor(message: string = 'Authentication required') {
    super(message, 401, 'AUTHENTICATION_ERROR')
  }
}

class AuthorizationError extends APIError {
  constructor(message: string = 'Permission denied') {
    super(message, 403, 'AUTHORIZATION_ERROR')
  }
}
```

## Request Validation

```typescript
// ✅ Validate content type
export async function POST(req: Request) {
  const contentType = req.headers.get('content-type')
  
  if (!contentType?.includes('application/json')) {
    return Response.json(
      { error: 'Content-Type must be application/json' },
      { status: 415 }
    )
  }

  // Limit request body size
  const MAX_BODY_SIZE = 1024 * 1024 // 1MB
  const contentLength = parseInt(req.headers.get('content-length') || '0')
  
  if (contentLength > MAX_BODY_SIZE) {
    return Response.json(
      { error: 'Request body too large' },
      { status: 413 }
    )
  }

  // Process request...
}
```

## Audit Checklist

```markdown
## API Security Audit

### Critical
- [ ] All endpoints require authentication (unless public)
- [ ] Authorization checks ownership/permissions
- [ ] No sensitive data in error responses
- [ ] Input validation on all endpoints

### High
- [ ] Rate limiting implemented
- [ ] CORS properly configured (no wildcard with credentials)
- [ ] API keys hashed before storage
- [ ] JWT algorithm explicitly specified

### Medium
- [ ] Request size limits enforced
- [ ] Content-Type validation
- [ ] Request logging for auditing
- [ ] API versioning strategy

### Low
- [ ] API documentation up to date
- [ ] Deprecation warnings for old versions
- [ ] Health check endpoints
```

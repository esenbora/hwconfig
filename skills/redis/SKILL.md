---
name: redis
description: Redis caching and data structure patterns
version: 1.0.0
---

# Redis

> **Priority:** CRITICAL | **Auto-Load:** On caching, session, realtime work
> **Triggers:** redis, upstash, cache, session, pub/sub, realtime

---

## Overview

Redis is an in-memory data store used for caching, session management, rate limiting, pub/sub messaging, and job queues. Upstash provides serverless Redis for edge/serverless deployments.

---

## Setup

### Upstash (Serverless - Recommended)

```typescript
// lib/redis.ts
import { Redis } from '@upstash/redis'

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

// Type-safe wrapper
export async function getCache<T>(key: string): Promise<T | null> {
  return redis.get<T>(key)
}

export async function setCache<T>(
  key: string,
  value: T,
  ttlSeconds?: number
): Promise<void> {
  if (ttlSeconds) {
    await redis.set(key, value, { ex: ttlSeconds })
  } else {
    await redis.set(key, value)
  }
}
```

### ioredis (Self-Hosted)

```typescript
// lib/redis.ts
import Redis from 'ioredis'

export const redis = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  lazyConnect: true,
})

// Connection events
redis.on('connect', () => console.log('Redis connected'))
redis.on('error', (err) => console.error('Redis error:', err))
```

---

## Caching Patterns

### Cache-Aside (Most Common)

```typescript
export async function getCached<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttl = 3600
): Promise<T> {
  // 1. Check cache
  const cached = await redis.get<T>(key)
  if (cached !== null) {
    return cached
  }

  // 2. Cache miss - fetch from source
  const data = await fetcher()

  // 3. Store in cache (fire and forget)
  redis.set(key, data, { ex: ttl }).catch(console.error)

  return data
}

// Usage
const user = await getCached(
  `user:${userId}`,
  () => db.user.findUnique({ where: { id: userId } }),
  300 // 5 min TTL
)
```

### Write-Through

```typescript
export async function updateWithCache<T>(
  key: string,
  updater: () => Promise<T>,
  ttl = 3600
): Promise<T> {
  // 1. Update source
  const data = await updater()

  // 2. Update cache
  await redis.set(key, data, { ex: ttl })

  return data
}
```

### Cache Invalidation

```typescript
// Single key
await redis.del(`user:${userId}`)

// Multiple keys
await redis.del([`user:${userId}`, `user:${email}`, `team:${teamId}:members`])

// Pattern-based (use with caution - expensive)
async function invalidatePattern(pattern: string) {
  const keys = await redis.keys(pattern)
  if (keys.length > 0) {
    await redis.del(...keys)
  }
}

// After mutation
async function updateUser(id: string, data: UpdateInput) {
  const user = await db.user.update({ where: { id }, data })

  // Invalidate related caches
  await Promise.all([
    redis.del(`user:${id}`),
    redis.del(`user:${user.email}`),
    invalidatePattern(`team:${user.teamId}:*`),
  ])

  return user
}
```

---

## Data Structures

### Strings (Key-Value)

```typescript
// Set with TTL
await redis.set('session:abc', JSON.stringify(sessionData), { ex: 86400 })

// Get
const session = await redis.get<SessionData>('session:abc')

// Increment (atomic)
await redis.incr('counter:visits')
await redis.incrby('counter:visits', 5)

// Set if not exists
const wasSet = await redis.setnx('lock:job-123', 'locked')
```

### Hashes (Objects)

```typescript
// Set fields
await redis.hset('user:123', {
  name: 'John',
  email: 'john@example.com',
  role: 'admin',
})

// Get single field
const name = await redis.hget('user:123', 'name')

// Get all fields
const user = await redis.hgetall('user:123')

// Increment field
await redis.hincrby('user:123', 'loginCount', 1)
```

### Lists (Queues)

```typescript
// Push to list (queue)
await redis.lpush('queue:emails', JSON.stringify(emailJob))

// Pop from list (FIFO)
const job = await redis.rpop('queue:emails')

// Blocking pop (wait for item)
const [, job] = await redis.brpop('queue:emails', 30) // 30s timeout

// Get range
const recent = await redis.lrange('recent:posts', 0, 9) // First 10
```

### Sets (Unique Collections)

```typescript
// Add members
await redis.sadd('tags:post-123', 'javascript', 'nodejs', 'redis')

// Check membership
const isMember = await redis.sismember('tags:post-123', 'redis')

// Get all members
const tags = await redis.smembers('tags:post-123')

// Intersection (common tags)
const common = await redis.sinter('tags:post-123', 'tags:post-456')
```

### Sorted Sets (Leaderboards)

```typescript
// Add with score
await redis.zadd('leaderboard:weekly', { score: 1500, member: 'user:123' })

// Get top 10
const top10 = await redis.zrevrange('leaderboard:weekly', 0, 9, {
  withScores: true,
})

// Get user rank
const rank = await redis.zrevrank('leaderboard:weekly', 'user:123')

// Increment score
await redis.zincrby('leaderboard:weekly', 10, 'user:123')
```

---

## Pub/Sub (Real-time Messaging)

### Publisher

```typescript
// Publish event
await redis.publish('events:user', JSON.stringify({
  type: 'user.updated',
  userId: '123',
  timestamp: Date.now(),
}))
```

### Subscriber

```typescript
import { Redis } from 'ioredis'

const subscriber = new Redis(process.env.REDIS_URL!)

subscriber.subscribe('events:user', 'events:order')

subscriber.on('message', (channel, message) => {
  const event = JSON.parse(message)

  switch (channel) {
    case 'events:user':
      handleUserEvent(event)
      break
    case 'events:order':
      handleOrderEvent(event)
      break
  }
})
```

### Cache Invalidation via Pub/Sub

```typescript
// Publisher (on data change)
async function notifyCacheInvalidation(pattern: string) {
  await redis.publish('cache:invalidate', JSON.stringify({ pattern }))
}

// Subscriber (all app instances)
subscriber.on('message', async (channel, message) => {
  if (channel === 'cache:invalidate') {
    const { pattern } = JSON.parse(message)
    await invalidateLocalCache(pattern)
  }
})
```

> ⚠️ **Warning:** Pub/Sub is best-effort and non-persistent. Messages are lost if no subscribers are listening.

---

## Session Management

```typescript
// lib/session.ts
const SESSION_TTL = 86400 * 7 // 7 days

export async function createSession(userId: string): Promise<string> {
  const sessionId = crypto.randomUUID()

  await redis.set(
    `session:${sessionId}`,
    JSON.stringify({ userId, createdAt: Date.now() }),
    { ex: SESSION_TTL }
  )

  return sessionId
}

export async function getSession(sessionId: string) {
  return redis.get<{ userId: string; createdAt: number }>(`session:${sessionId}`)
}

export async function deleteSession(sessionId: string) {
  await redis.del(`session:${sessionId}`)
}

export async function extendSession(sessionId: string) {
  await redis.expire(`session:${sessionId}`, SESSION_TTL)
}
```

---

## Rate Limiting

See `rate-limiting` skill for comprehensive patterns. Quick example:

```typescript
import { Ratelimit } from '@upstash/ratelimit'

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})

export async function checkRateLimit(identifier: string) {
  const { success, limit, remaining, reset } = await ratelimit.limit(identifier)
  return { success, limit, remaining, reset }
}
```

---

## Best Practices

### Key Naming Convention

```typescript
// Pattern: {type}:{id}:{subtype}
const patterns = {
  user: 'user:123',
  userProfile: 'user:123:profile',
  userSessions: 'user:123:sessions',
  cache: 'cache:api:/users',
  lock: 'lock:job:send-emails',
  queue: 'queue:emails',
  ratelimit: 'ratelimit:api:user:123',
}
```

### TTL Recommendations

| Use Case | TTL | Notes |
|----------|-----|-------|
| User session | 7 days | Extend on activity |
| API cache | 1-5 min | Short for freshness |
| User profile | 5-30 min | Invalidate on update |
| Static data | 1-24 hours | Longer for stability |
| Rate limit | 1-15 min | Based on window |
| Locks | 30s-5min | With auto-release |

### Error Handling

```typescript
export async function safeCache<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttl = 3600
): Promise<T> {
  try {
    const cached = await redis.get<T>(key)
    if (cached !== null) return cached
  } catch (error) {
    // Redis down - continue without cache
    console.error('Redis get error:', error)
  }

  const data = await fetcher()

  try {
    await redis.set(key, data, { ex: ttl })
  } catch (error) {
    // Redis down - data still returned
    console.error('Redis set error:', error)
  }

  return data
}
```

### Memory Management

```typescript
// Set max memory policy in Redis config
// maxmemory-policy allkeys-lru

// Always set TTL on cache keys
await redis.set('cache:data', value, { ex: 3600 })

// Monitor memory usage
const info = await redis.info('memory')
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| No TTL on cache | Memory leak | Always set TTL |
| Storing large objects | Slow, memory heavy | Store IDs, fetch details |
| Using KEYS in prod | Blocks Redis | Use SCAN or avoid |
| Single Redis instance | Single point of failure | Use cluster/Upstash |
| Caching errors | Serving bad data | Only cache success |

---

## Checklist

```markdown
Setup:
[ ] Redis client configured with error handling
[ ] Connection pooling (for non-serverless)
[ ] Environment variables for credentials

Caching:
[ ] TTL set on all cache keys
[ ] Invalidation on mutations
[ ] Error fallback (continue without cache)

Security:
[ ] AUTH enabled
[ ] TLS for remote connections
[ ] No sensitive data in keys

Monitoring:
[ ] Connection events logged
[ ] Memory usage monitored
[ ] Slow queries tracked
```

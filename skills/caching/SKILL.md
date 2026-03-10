---
name: caching
description: Use when things are slow, making too many requests, or need performance optimization. Redis, HTTP cache, TanStack Query, cache invalidation. Triggers on: cache, caching, redis, slow, performance, staleTime, revalidate, too many requests, optimize, faster, upstash.
version: 1.0.0
---

# Caching Strategies

> **Priority:** RECOMMENDED | **Auto-Load:** On caching/performance work
> **Triggers:** cache, redis, caching, invalidate, ttl, stale, swr

---

## Overview

Effective caching can dramatically improve application performance. This skill covers caching patterns at multiple levels: HTTP, application, and database.

---

## Caching Layers

| Layer | Technology | TTL | Use Case |
|-------|------------|-----|----------|
| **Browser** | HTTP headers | Seconds to days | Static assets |
| **CDN** | Edge caching | Minutes to hours | Public pages, assets |
| **Application** | Redis, Memory | Seconds to hours | Session, computed data |
| **Query** | TanStack Query | Minutes | API responses |
| **Database** | Materialized views | Hours to days | Aggregations |

---

## Redis Caching

### Setup

```typescript
// lib/redis.ts
import { Redis } from '@upstash/redis';

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// For Node.js (not serverless)
import { createClient } from 'redis';

export const redis = createClient({
  url: process.env.REDIS_URL,
});
await redis.connect();
```

### Generic Cache Pattern

```typescript
// lib/cache.ts
import { redis } from './redis';

type CacheOptions = {
  ttl?: number;      // Seconds
  staleWhileRevalidate?: number;  // Additional seconds to serve stale
};

export async function cached<T>(
  key: string,
  fetcher: () => Promise<T>,
  options: CacheOptions = {}
): Promise<T> {
  const { ttl = 3600, staleWhileRevalidate = 0 } = options;
  const cacheKey = `cache:${key}`;

  // Try cache first
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached as string) as T;
  }

  // Fetch fresh data
  const data = await fetcher();

  // Store in cache (fire and forget)
  redis.set(cacheKey, JSON.stringify(data), {
    ex: ttl + staleWhileRevalidate,
  }).catch(console.error);

  return data;
}

// Usage
const user = await cached(
  `user:${userId}`,
  () => db.user.findUnique({ where: { id: userId } }),
  { ttl: 300 }  // 5 minutes
);
```

### Cache Invalidation

```typescript
// lib/cache.ts
export async function invalidateCache(pattern: string): Promise<void> {
  const keys = await redis.keys(`cache:${pattern}`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
}

// Invalidate single key
export async function invalidateCacheKey(key: string): Promise<void> {
  await redis.del(`cache:${key}`);
}

// Usage after mutation
async function updateUser(id: string, data: UpdateUserInput) {
  const user = await db.user.update({ where: { id }, data });

  // Invalidate related caches
  await Promise.all([
    invalidateCacheKey(`user:${id}`),
    invalidateCacheKey(`user:${user.email}`),
    invalidateCache(`team:${user.teamId}:*`),
  ]);

  return user;
}
```

### Cache-Aside Pattern

```typescript
class UserService {
  async getUser(id: string): Promise<User | null> {
    // 1. Check cache
    const cached = await redis.get(`user:${id}`);
    if (cached) return JSON.parse(cached);

    // 2. Cache miss - fetch from DB
    const user = await db.user.findUnique({ where: { id } });
    if (!user) return null;

    // 3. Populate cache
    await redis.set(`user:${id}`, JSON.stringify(user), { ex: 3600 });

    return user;
  }

  async updateUser(id: string, data: UpdateUserInput): Promise<User> {
    // 1. Update DB
    const user = await db.user.update({ where: { id }, data });

    // 2. Invalidate cache (don't update - avoids race conditions)
    await redis.del(`user:${id}`);

    return user;
  }
}
```

---

## HTTP Caching

### Cache-Control Headers

```typescript
// Next.js API Route
export async function GET(request: Request) {
  const data = await fetchData();

  return new Response(JSON.stringify(data), {
    headers: {
      'Content-Type': 'application/json',
      // Public: Can be cached by CDN
      // max-age: Browser cache for 60 seconds
      // s-maxage: CDN cache for 300 seconds
      // stale-while-revalidate: Serve stale for 600s while revalidating
      'Cache-Control': 'public, max-age=60, s-maxage=300, stale-while-revalidate=600',
    },
  });
}
```

### Common Cache-Control Patterns

```typescript
const cacheHeaders = {
  // Static assets (immutable)
  staticAsset: 'public, max-age=31536000, immutable',

  // Public page (short)
  publicPage: 'public, max-age=60, s-maxage=300',

  // User-specific data (private)
  userData: 'private, max-age=0, must-revalidate',

  // API response (short, revalidate)
  apiResponse: 'public, max-age=10, stale-while-revalidate=60',

  // No cache
  noCache: 'no-store, no-cache, must-revalidate',
};
```

### ETag for Conditional Requests

```typescript
import { createHash } from 'crypto';

export async function GET(request: Request) {
  const data = await fetchData();
  const etag = createHash('md5').update(JSON.stringify(data)).digest('hex');

  // Check If-None-Match header
  const ifNoneMatch = request.headers.get('if-none-match');
  if (ifNoneMatch === etag) {
    return new Response(null, { status: 304 });
  }

  return new Response(JSON.stringify(data), {
    headers: {
      'Content-Type': 'application/json',
      'ETag': etag,
      'Cache-Control': 'public, max-age=0, must-revalidate',
    },
  });
}
```

---

## Next.js Caching

### Data Cache (fetch)

```typescript
// Cached for entire build (SSG)
const data = await fetch('https://api.example.com/data');

// Revalidate every 60 seconds (ISR)
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 60 },
});

// No cache (SSR)
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store',
});

// Tag-based invalidation
const data = await fetch('https://api.example.com/posts', {
  next: { tags: ['posts'] },
});

// Invalidate by tag
import { revalidateTag } from 'next/cache';
revalidateTag('posts');
```

### Route Segment Config

```typescript
// app/api/users/route.ts

// Force dynamic (no cache)
export const dynamic = 'force-dynamic';

// Force static (cache at build)
export const dynamic = 'force-static';

// Revalidate every 60 seconds
export const revalidate = 60;
```

### unstable_cache

```typescript
import { unstable_cache } from 'next/cache';

const getCachedUser = unstable_cache(
  async (id: string) => {
    return db.user.findUnique({ where: { id } });
  },
  ['user'],  // Cache key prefix
  {
    revalidate: 3600,  // 1 hour
    tags: ['users'],   // For tag-based invalidation
  }
);

// Usage
const user = await getCachedUser(userId);

// Invalidate
import { revalidateTag } from 'next/cache';
revalidateTag('users');
```

---

## SWR (Stale-While-Revalidate)

### Client-Side Caching

```typescript
import useSWR from 'swr';

function Profile() {
  const { data, error, isLoading, mutate } = useSWR(
    '/api/user',
    (url) => fetch(url).then((r) => r.json()),
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: true,
      dedupingInterval: 2000,
    }
  );

  // Optimistic update
  const updateUser = async (newData) => {
    await mutate(
      async () => {
        await fetch('/api/user', {
          method: 'PUT',
          body: JSON.stringify(newData),
        });
        return newData;
      },
      { optimisticData: newData, rollbackOnError: true }
    );
  };
}
```

---

## Cache Invalidation Strategies

### Time-Based (TTL)

```typescript
// Simple TTL
await redis.set('key', value, { ex: 3600 });  // Expires in 1 hour

// TTL with stale window
const TTL = 300;           // 5 min fresh
const STALE_TTL = 3600;    // 1 hour stale

await redis.set('key', JSON.stringify({
  data: value,
  cachedAt: Date.now(),
}), { ex: STALE_TTL });

// Check freshness
const cached = await redis.get('key');
const { data, cachedAt } = JSON.parse(cached);
const isStale = Date.now() - cachedAt > TTL * 1000;

if (isStale) {
  // Revalidate in background
  revalidate().catch(console.error);
}
return data;
```

### Event-Based

```typescript
// Pub/Sub invalidation
const subscriber = redis.duplicate();
await subscriber.subscribe('cache:invalidate');

subscriber.on('message', async (channel, message) => {
  const { pattern } = JSON.parse(message);
  await invalidateCache(pattern);
});

// Publish invalidation event
async function publishInvalidation(pattern: string) {
  await redis.publish('cache:invalidate', JSON.stringify({ pattern }));
}

// Usage after mutation
await updateUser(id, data);
await publishInvalidation(`user:${id}:*`);
```

### Versioned Cache Keys

```typescript
// Include version in cache key
const CACHE_VERSION = 'v2';

function getCacheKey(type: string, id: string) {
  return `${CACHE_VERSION}:${type}:${id}`;
}

// When data structure changes, increment version
// Old keys naturally expire, no migration needed
```

---

## Cache Warming

```typescript
// Warm cache on deploy or schedule
async function warmCache() {
  // Most accessed users
  const topUsers = await db.user.findMany({
    take: 100,
    orderBy: { accessCount: 'desc' },
  });

  await Promise.all(
    topUsers.map((user) =>
      redis.set(`user:${user.id}`, JSON.stringify(user), { ex: 3600 })
    )
  );
}

// Run on deploy
warmCache().catch(console.error);
```

---

## Caching Anti-Patterns

### ❌ Cache Everything

```typescript
// BAD - Caching user-specific data globally
await redis.set('user', userData);  // Wrong! Which user?

// GOOD - Include user ID in key
await redis.set(`user:${userId}`, userData);
```

### ❌ Forget to Invalidate

```typescript
// BAD - Update without invalidation
await db.user.update({ where: { id }, data });
// Cache still has old data!

// GOOD - Always invalidate
await db.user.update({ where: { id }, data });
await redis.del(`user:${id}`);
```

### ❌ Cache Failures

```typescript
// BAD - Cache errors like they're data
const result = await fetchData();
if (result.error) {
  await redis.set(key, result);  // Don't cache errors!
}

// GOOD - Only cache successful responses
const result = await fetchData();
if (!result.error) {
  await redis.set(key, result);
}
```

---

## TTL Recommendations

| Data Type | TTL | Invalidation |
|-----------|-----|--------------|
| User session | 24h | On logout |
| User profile | 5-30 min | On update |
| API response | 1-5 min | Event-based |
| Search results | 1-5 min | Time-based |
| Static content | 1+ hour | On deploy |
| Feature flags | 1-5 min | On change |
| Rate limit counters | 1 min | Never (auto-expire) |

---

## Quick Reference

| Operation | Redis Command |
|-----------|--------------|
| Set with TTL | `SET key value EX 3600` |
| Get | `GET key` |
| Delete | `DEL key` |
| Delete pattern | `KEYS pattern` → `DEL keys` |
| Check TTL | `TTL key` |
| Set if not exists | `SETNX key value` |
| Increment | `INCR key` |

---

## Resources

- [Redis Documentation](https://redis.io/docs/)
- [Next.js Caching](https://nextjs.org/docs/app/building-your-application/caching)
- [HTTP Caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
- [SWR Documentation](https://swr.vercel.app/)

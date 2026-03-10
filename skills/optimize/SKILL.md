---
name: optimize
description: Use when improving performance, speed, or efficiency. Measure first, then optimize. Triggers on: optimize, performance, slow, speed up, faster, bundle size, lighthouse, core web vitals, profiling.
argument-hint: "<area: frontend | backend | database | bundle | caching>"
version: 1.0.0
context: fork
agent: performance
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Task
---

# Performance Optimization

**Optimize:** $ARGUMENTS

---

## GOLDEN RULE

```
MEASURE FIRST, OPTIMIZE SECOND

1. MEASURE current performance (baseline)
2. IDENTIFY the actual bottleneck
3. OPTIMIZE the bottleneck (one at a time)
4. MEASURE again to verify improvement

No measurement = No optimization
```

---

## PHASE 1: MEASURE BASELINE

### Frontend Metrics

```bash
# Lighthouse audit
npx lighthouse https://site.com --output=html

# Bundle analysis
npx @next/bundle-analyzer
```

**Core Web Vitals Targets:**

| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP | < 2.5s | 2.5-4s | > 4s |
| INP | < 200ms | 200-500ms | > 500ms |
| CLS | < 0.1 | 0.1-0.25 | > 0.25 |
| TTFB | < 800ms | 800-1800ms | > 1800ms |

### Backend Metrics

```sql
-- Find slow queries (PostgreSQL)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...

-- Key indicators:
-- Seq Scan on large table = needs index
-- Nested Loop with high rows = wrong join type
-- Buffers: shared read vs hit = cache misses
```

---

## PHASE 2: IDENTIFY BOTTLENECKS

### Frontend Issues

| Issue | Detection |
|-------|-----------|
| Large bundle | Bundle analyzer |
| Unoptimized images | Lighthouse |
| No code splitting | Network tab |
| Layout shifts | CLS debugger |

### Backend Issues

| Issue | Detection |
|-------|-----------|
| N+1 queries | Query logging |
| Missing indexes | EXPLAIN ANALYZE |
| No caching | Repeated fetches |
| Large payloads | Response size |

---

## PHASE 3: OPTIMIZE

### Frontend

```typescript
// Images - Next.js
<Image src="/hero.jpg" priority placeholder="blur" sizes="..." />

// Code splitting
const Heavy = dynamic(() => import('./Heavy'), { ssr: false })

// Bundle - tree-shake imports
import { debounce } from 'lodash-es'  // not 'lodash'
```

### Backend (Drizzle)

```typescript
// Prepared statements
const getUserById = db.select().from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare('get_user_by_id')

// Eager loading (avoid N+1)
const posts = await db.select({ post: postsTable, author: usersTable })
  .from(postsTable)
  .leftJoin(usersTable, eq(postsTable.authorId, usersTable.id))
```

### Caching

```typescript
// TanStack Query (client)
useQuery({
  queryKey: ['users', id],
  queryFn: () => fetchUser(id),
  staleTime: 5 * 60 * 1000,  // 5 min
})

// Redis (server)
const cached = await redis.get(key)
if (cached) return cached
const data = await fetcher()
await redis.set(key, data, { ex: ttl })
```

---

## PHASE 4: VERIFY

```markdown
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| [X] | Y | Z | % |
```

- [ ] All tests pass
- [ ] No regressions
- [ ] Improvement verified with evidence

---

## MOBILE (Expo/RN)

### Targets

| Metric | Target |
|--------|--------|
| Cold start | < 2s |
| Frame rate | 60 FPS |
| Bundle size | Minimize |

### Key Optimizations

```typescript
// Lists - use FlashList
import { FlashList } from '@shopify/flash-list'
<FlashList data={items} estimatedItemSize={80} />

// Images - use expo-image
import { Image } from 'expo-image'
<Image source={url} cachePolicy="memory-disk" />

// Animations - use native driver
Animated.timing(value, { useNativeDriver: true })
// Or Reanimated for complex animations

// Memoize components
const Item = memo(({ item }) => <View>{item.name}</View>)
```

---

## ANTI-PATTERNS

- Optimizing without measuring
- Premature optimization
- Breaking functionality for speed
- Caching without invalidation plan

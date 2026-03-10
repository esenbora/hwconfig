---
name: defensive-coding
description: Use for any code you write. Handle edge cases, validate inputs, expect failure. Always active.
version: 1.0.0
---

# Defensive Coding

Assume everything will fail. Code for the worst case. The happy path is the exception, not the rule.

## The Edge Case Mindset

For every piece of code, ask:
- What if this is null/undefined?
- What if this is empty?
- What if this fails?
- What if this times out?
- What if this is called twice?

## Null Safety

```typescript
// ❌ Assumes data exists
const userName = user.profile.name.first

// ✅ Optional chaining
const userName = user?.profile?.name?.first

// ✅ Nullish coalescing for defaults
const userName = user?.profile?.name?.first ?? 'Anonymous'

// ✅ Type guard for critical paths
if (!user?.profile?.name?.first) {
  throw new Error('User name is required')
}
const userName = user.profile.name.first // Now safe
```

## Array Safety

```typescript
// ❌ Assumes array has items
const firstItem = items[0]
const lastItem = items[items.length - 1]

// ✅ Check first
const firstItem = items.at(0)
if (!firstItem) {
  return <EmptyState />
}

// ✅ Safe array methods
const filtered = items?.filter(i => i.active) ?? []
const mapped = items?.map(i => i.id) ?? []

// ✅ Check before destructuring
const [first, ...rest] = items ?? []
if (!first) {
  // Handle empty case
}
```

## Network Resilience

```typescript
// ❌ Assumes network always works
const data = await fetch('/api/data').then(r => r.json())

// ✅ Handle all failure modes
async function fetchWithRetry<T>(
  url: string,
  options?: RequestInit,
  retries = 3
): Promise<T> {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const controller = new AbortController()
      const timeout = setTimeout(() => controller.abort(), 10000)
      
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      })
      
      clearTimeout(timeout)
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }
      
      return response.json()
      
    } catch (error) {
      if (attempt === retries) throw error
      await new Promise(r => setTimeout(r, 1000 * attempt))
    }
  }
  
  throw new Error('Max retries exceeded')
}
```

## Race Conditions

```typescript
// ❌ Race condition prone
useEffect(() => {
  fetch(`/api/users/${userId}`)
    .then(r => r.json())
    .then(setUser)
}, [userId])

// ✅ Handle race conditions
useEffect(() => {
  let cancelled = false
  const controller = new AbortController()
  
  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(r => r.json())
    .then(data => {
      if (!cancelled) setUser(data)
    })
    .catch(err => {
      if (!cancelled && err.name !== 'AbortError') {
        setError(err)
      }
    })
  
  return () => {
    cancelled = true
    controller.abort()
  }
}, [userId])

// ✅ Or use React Query (handles this automatically)
const { data: user } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetchUser(userId),
})
```

## Double Submit Prevention

```typescript
// ❌ Allows double submit
<form onSubmit={handleSubmit}>
  <button type="submit">Submit</button>
</form>

// ✅ Prevent double submit
const [isSubmitting, setIsSubmitting] = useState(false)

async function handleSubmit(e: FormEvent) {
  e.preventDefault()
  if (isSubmitting) return
  
  setIsSubmitting(true)
  try {
    await submitForm()
  } finally {
    setIsSubmitting(false)
  }
}

<form onSubmit={handleSubmit}>
  <button type="submit" disabled={isSubmitting}>
    {isSubmitting ? 'Submitting...' : 'Submit'}
  </button>
</form>
```

## Boundary Values

```typescript
// ❌ Doesn't handle boundaries
function getDiscount(quantity: number) {
  if (quantity > 10) return 0.2
  if (quantity > 5) return 0.1
  return 0
}

// ✅ Handle all boundaries
function getDiscount(quantity: number) {
  if (quantity < 0) throw new Error('Quantity cannot be negative')
  if (quantity === 0) return 0
  if (!Number.isFinite(quantity)) throw new Error('Invalid quantity')
  
  if (quantity > 10) return 0.2
  if (quantity > 5) return 0.1
  return 0
}
```

## Idempotency

```typescript
// ❌ Non-idempotent (double charge possible)
async function chargeUser(userId: string, amount: number) {
  await stripe.charges.create({ amount, customer: userId })
}

// ✅ Idempotent with key
async function chargeUser(
  userId: string, 
  amount: number, 
  orderId: string
) {
  await stripe.charges.create(
    { amount, customer: userId },
    { idempotencyKey: `charge-${orderId}` }
  )
}
```

## Defensive Database

```typescript
// ❌ Assumes insert succeeds
await db.user.create({ data: userData })

// ✅ Handle constraints
try {
  await db.user.create({ data: userData })
} catch (error) {
  if (error.code === 'P2002') {
    // Unique constraint violation
    throw new AppError('Email already exists', 'DUPLICATE_EMAIL')
  }
  throw error
}

// ✅ Use upsert for create-or-update
await db.user.upsert({
  where: { email: userData.email },
  create: userData,
  update: userData,
})
```

## Component Unmount Safety

```typescript
// ❌ State update after unmount
useEffect(() => {
  fetchData().then(data => setData(data))
}, [])

// ✅ Check if mounted
useEffect(() => {
  let mounted = true
  
  fetchData().then(data => {
    if (mounted) setData(data)
  })
  
  return () => {
    mounted = false
  }
}, [])
```

## Defensive Checklist

```markdown
Null/Undefined:
[ ] Optional chaining used
[ ] Default values provided
[ ] Null checks before use

Arrays:
[ ] Empty array handling
[ ] Bounds checking
[ ] Safe array methods

Network:
[ ] Timeout handling
[ ] Retry logic
[ ] Abort on unmount

State:
[ ] Race conditions handled
[ ] Double submit prevented
[ ] Unmount safety

Data:
[ ] Input validation
[ ] Boundary values checked
[ ] Database constraints handled
```

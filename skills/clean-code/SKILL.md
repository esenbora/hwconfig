---
name: clean-code
description: Use for any code you write. Readable, maintainable, simple code patterns. Always active.
version: 1.0.0
---

# Clean Code

Write code that humans can read and maintain. Cleverness is the enemy of clarity.

## Naming

### Functions: Verb + Noun

```typescript
// ❌ Unclear
function data() { }
function process() { }
function handle() { }

// ✅ Clear
function fetchUserProfile() { }
function validateEmail() { }
function handleFormSubmit() { }
```

### Variables: Describe Content

```typescript
// ❌ Cryptic
const d = new Date()
const arr = users.filter(u => u.a)
const temp = calculateTotal()

// ✅ Descriptive
const createdAt = new Date()
const activeUsers = users.filter(user => user.isActive)
const orderTotal = calculateTotal()
```

### Booleans: is/has/can/should

```typescript
// ❌ Ambiguous
const admin = user.role === 'admin'
const loading = true
const visible = !hidden

// ✅ Clear
const isAdmin = user.role === 'admin'
const isLoading = true
const isVisible = !isHidden
```

## Functions

### Single Responsibility

```typescript
// ❌ Does too much
function processUserData(data) {
  validateData(data)
  const formatted = formatData(data)
  saveToDatabase(formatted)
  sendEmail(data.email)
  logAnalytics('user_created')
  return formatted
}

// ✅ Single purpose
function createUser(data: UserInput): User {
  const validated = validateUserInput(data)
  return db.user.create({ data: validated })
}

// Orchestrate separately
async function handleUserRegistration(data: UserInput) {
  const user = await createUser(data)
  await sendWelcomeEmail(user.email)
  trackEvent('user_created', { userId: user.id })
  return user
}
```

### Limit Parameters

```typescript
// ❌ Too many parameters
function createOrder(
  userId, productId, quantity, address, 
  paymentMethod, couponCode, giftWrap, message
) { }

// ✅ Use object parameter
interface CreateOrderInput {
  userId: string
  productId: string
  quantity: number
  shipping: ShippingDetails
  payment: PaymentDetails
  options?: OrderOptions
}

function createOrder(input: CreateOrderInput) { }
```

### Early Return

```typescript
// ❌ Deep nesting
function processOrder(order) {
  if (order) {
    if (order.items.length > 0) {
      if (order.status === 'pending') {
        // actual logic here
      }
    }
  }
}

// ✅ Early return
function processOrder(order) {
  if (!order) return null
  if (order.items.length === 0) return null
  if (order.status !== 'pending') return null
  
  // actual logic here
}
```

## DRY (Don't Repeat Yourself)

### Extract Repeated Logic

```typescript
// ❌ Repeated
const totalA = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
const totalB = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)

// ✅ Extracted
function calculateTotal(items: LineItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
}

const totalA = calculateTotal(items)
const totalB = calculateTotal(cart)
```

### But Don't Over-Abstract

```typescript
// ❌ Over-abstracted (harder to understand)
const result = compose(
  filter(isActive),
  map(toDTO),
  reduce(mergeById, {})
)(users)

// ✅ Clear, even if slightly longer
const activeUsers = users.filter(user => user.isActive)
const userDTOs = activeUsers.map(user => toDTO(user))
const usersById = userDTOs.reduce((acc, user) => {
  acc[user.id] = user
  return acc
}, {})
```

## Comments

### When to Comment

```typescript
// ✅ Explain WHY, not what
// Using a 5-minute cache because user profile rarely changes
// and API has a 100 req/min rate limit
const CACHE_TTL = 5 * 60 * 1000

// ✅ Document non-obvious behavior
// Returns null instead of throwing because callers expect
// missing users to be a normal case, not an error
function findUser(id: string): User | null { }

// ✅ TODO with context
// TODO(#123): Refactor when we add multi-currency support
const formatPrice = (cents: number) => `$${(cents / 100).toFixed(2)}`
```

### When NOT to Comment

```typescript
// ❌ Comments that state the obvious
// Increment counter by 1
counter++

// ❌ Comments that duplicate code
// Check if user is admin
if (user.role === 'admin') { }
```

## File Organization

```typescript
// Recommended order in a file:

// 1. Imports (grouped: external, internal, types)
import { useState } from 'react'
import { db } from '@/lib/db'
import type { User } from '@/types'

// 2. Types/Interfaces
interface Props {
  user: User
}

// 3. Constants
const MAX_ITEMS = 10

// 4. Helper functions
function formatName(user: User): string {
  return `${user.firstName} ${user.lastName}`
}

// 5. Main export
export function UserCard({ user }: Props) {
  // ...
}
```

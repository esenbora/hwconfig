---
name: sentry
description: Use when setting up Sentry for error tracking. Integration, error context, performance. Triggers on: sentry, error tracking, crash reporting, performance monitoring, sentry integration.
version: 1.0.0
detect: ["@sentry/nextjs"]
---

# Sentry

Error tracking and performance monitoring.

## Setup

```bash
npx @sentry/wizard@latest -i nextjs
```

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  integrations: [
    Sentry.replayIntegration({
      maskAllText: false,
      blockAllMedia: false,
    }),
  ],
})

// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
})

// sentry.edge.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
})
```

## Configuration

```typescript
// next.config.ts
import { withSentryConfig } from '@sentry/nextjs'

const nextConfig = {
  // Your config
}

export default withSentryConfig(nextConfig, {
  org: 'your-org',
  project: 'your-project',
  silent: true,
  widenClientFileUpload: true,
  hideSourceMaps: true,
  disableLogger: true,
})
```

## Error Boundary

```tsx
// app/global-error.tsx
'use client'

import * as Sentry from '@sentry/nextjs'
import { useEffect } from 'react'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    Sentry.captureException(error)
  }, [error])

  return (
    <html>
      <body>
        <h2>Something went wrong!</h2>
        <button onClick={() => reset()}>Try again</button>
      </body>
    </html>
  )
}

// app/error.tsx (page-level)
'use client'

import * as Sentry from '@sentry/nextjs'
import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    Sentry.captureException(error)
  }, [error])

  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  )
}
```

## Manual Error Capture

```typescript
import * as Sentry from '@sentry/nextjs'

// Capture exception
try {
  await riskyOperation()
} catch (error) {
  Sentry.captureException(error, {
    tags: {
      section: 'checkout',
    },
    extra: {
      userId: user.id,
      orderId: order.id,
    },
  })
}

// Capture message
Sentry.captureMessage('Something unusual happened', {
  level: 'warning',
  tags: { feature: 'payments' },
})
```

## User Context

```typescript
// Set user context
Sentry.setUser({
  id: user.id,
  email: user.email,
  username: user.name,
})

// Clear on logout
Sentry.setUser(null)
```

## Custom Context

```typescript
// Add context
Sentry.setContext('order', {
  id: order.id,
  total: order.total,
  items: order.items.length,
})

// Add tags
Sentry.setTag('feature', 'checkout')
Sentry.setTag('plan', user.plan)

// Add breadcrumb
Sentry.addBreadcrumb({
  category: 'user',
  message: 'User clicked checkout button',
  level: 'info',
})
```

## Performance Monitoring

```typescript
// Custom transaction
const transaction = Sentry.startTransaction({
  name: 'processOrder',
  op: 'task',
})

try {
  const span = transaction.startChild({
    op: 'db.query',
    description: 'Fetch inventory',
  })
  await fetchInventory()
  span.finish()

  const paymentSpan = transaction.startChild({
    op: 'http.client',
    description: 'Process payment',
  })
  await processPayment()
  paymentSpan.finish()
} finally {
  transaction.finish()
}
```

## Server Action Instrumentation

```typescript
'use server'

import * as Sentry from '@sentry/nextjs'

export async function createOrder(formData: FormData) {
  return Sentry.withServerActionInstrumentation(
    'createOrder',
    { recordResponse: true },
    async () => {
      try {
        const order = await db.order.create({
          data: { /* ... */ },
        })
        return { success: true, order }
      } catch (error) {
        Sentry.captureException(error)
        return { success: false, error: 'Failed to create order' }
      }
    }
  )
}
```

## API Route Instrumentation

```typescript
// app/api/orders/route.ts
import * as Sentry from '@sentry/nextjs'

export async function POST(request: Request) {
  return Sentry.withIsolationScope(async (scope) => {
    scope.setTag('endpoint', 'create-order')

    try {
      const body = await request.json()
      const order = await createOrder(body)
      return Response.json(order)
    } catch (error) {
      Sentry.captureException(error)
      return Response.json({ error: 'Internal error' }, { status: 500 })
    }
  })
}
```

## Source Maps

```typescript
// next.config.ts
export default withSentryConfig(nextConfig, {
  // Upload source maps for better stack traces
  hideSourceMaps: true,
  widenClientFileUpload: true,
  
  // For debugging in development
  disableLogger: process.env.NODE_ENV === 'production',
})
```

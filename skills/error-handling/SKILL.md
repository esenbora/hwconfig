---
name: error-handling
description: Handle all errors gracefully, never happy-path only. Always active.
version: 1.0.0
---

# Error Handling

Errors are not exceptions - they're expected. Handle them gracefully. Never let users see raw errors.

## Error Categories

| Category | Example | Handling |
|----------|---------|----------|
| **Expected** | Not found, validation | User-friendly message |
| **Operational** | Network, timeout | Retry or graceful degradation |
| **Programming** | TypeError, null ref | Fix the bug |
| **Fatal** | Out of memory | Crash and restart |

## Typed Errors

```typescript
// lib/errors.ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 400,
    public isOperational: boolean = true
  ) {
    super(message)
    this.name = 'AppError'
  }
}

// Predefined errors
export const Errors = {
  // Auth
  UNAUTHORIZED: new AppError('Please sign in to continue', 'UNAUTHORIZED', 401),
  FORBIDDEN: new AppError('You don\'t have permission', 'FORBIDDEN', 403),
  
  // Resources
  NOT_FOUND: (resource: string) => 
    new AppError(`${resource} not found`, 'NOT_FOUND', 404),
  
  // Validation
  VALIDATION: (message: string, field?: string) => 
    new AppError(message, 'VALIDATION', 400),
  
  // Rate limiting
  RATE_LIMITED: new AppError(
    'Too many requests. Please try again later.', 
    'RATE_LIMITED', 
    429
  ),
  
  // Server
  INTERNAL: new AppError(
    'Something went wrong. Please try again.',
    'INTERNAL_ERROR',
    500
  ),
}
```

## Server Action Errors

```typescript
'use server'

import { z } from 'zod'

// Define result type
type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string; field?: string }

const createProjectSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  description: z.string().max(500).optional(),
})

export async function createProject(
  formData: FormData
): Promise<ActionResult<{ id: string }>> {
  try {
    // Auth check
    const session = await auth()
    if (!session?.user) {
      return { success: false, error: 'Please sign in to continue' }
    }

    // Validation
    const parsed = createProjectSchema.safeParse({
      name: formData.get('name'),
      description: formData.get('description'),
    })

    if (!parsed.success) {
      const error = parsed.error.errors[0]
      return {
        success: false,
        error: error.message,
        field: error.path[0]?.toString(),
      }
    }

    // Business logic
    const project = await db.project.create({
      data: {
        ...parsed.data,
        userId: session.user.id,
      },
    })

    return { success: true, data: { id: project.id } }

  } catch (error) {
    // Log for debugging
    console.error('createProject error:', error)
    
    // Generic message for user
    return { 
      success: false, 
      error: 'Failed to create project. Please try again.' 
    }
  }
}
```

## API Route Errors

```typescript
// app/api/projects/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { Errors } from '@/lib/errors'

export async function GET(request: NextRequest) {
  try {
    const session = await auth()
    if (!session?.user) {
      return NextResponse.json(
        { error: Errors.UNAUTHORIZED.message, code: Errors.UNAUTHORIZED.code },
        { status: 401 }
      )
    }

    const projects = await db.project.findMany({
      where: { userId: session.user.id },
    })

    return NextResponse.json({ data: projects })

  } catch (error) {
    console.error('GET /api/projects:', error)
    
    return NextResponse.json(
      { error: 'Something went wrong', code: 'INTERNAL_ERROR' },
      { status: 500 }
    )
  }
}
```

## React Error Boundaries

```typescript
// components/error-boundary.tsx
'use client'

import { Component, ErrorInfo, ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode | ((error: Error, reset: () => void) => ReactNode)
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error boundary caught:', error, errorInfo)
    // Send to error tracking (Sentry)
  }

  reset = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError) {
      if (typeof this.props.fallback === 'function') {
        return this.props.fallback(this.state.error!, this.reset)
      }
      return this.props.fallback ?? <DefaultErrorUI reset={this.reset} />
    }

    return this.props.children
  }
}

function DefaultErrorUI({ reset }: { reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center p-8">
      <h2 className="text-lg font-semibold">Something went wrong</h2>
      <p className="text-muted-foreground mb-4">
        We're sorry, but something unexpected happened.
      </p>
      <button onClick={reset} className="btn-primary">
        Try again
      </button>
    </div>
  )
}
```

## Async Error Handling

```typescript
// With async/await
async function fetchUser(id: string): Promise<User | null> {
  try {
    const response = await fetch(`/api/users/${id}`)
    
    if (!response.ok) {
      if (response.status === 404) return null
      throw new Error(`HTTP ${response.status}`)
    }
    
    return response.json()
  } catch (error) {
    console.error('fetchUser error:', error)
    throw new AppError('Failed to load user', 'FETCH_ERROR')
  }
}

// React Query error handling
const { data, error, isError, refetch } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetchUser(userId),
  retry: 3,
  retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
})

if (isError) {
  return <ErrorState error={error.message} retry={refetch} />
}
```

## Error UI Components

```typescript
// components/error-state.tsx
interface ErrorStateProps {
  title?: string
  message?: string
  retry?: () => void
}

export function ErrorState({ 
  title = 'Something went wrong',
  message = 'Please try again later.',
  retry 
}: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center">
      <AlertCircle className="h-12 w-12 text-destructive mb-4" />
      <h3 className="font-semibold text-lg">{title}</h3>
      <p className="text-muted-foreground mb-4">{message}</p>
      {retry && (
        <Button onClick={retry} variant="outline">
          <RefreshCw className="mr-2 h-4 w-4" />
          Try again
        </Button>
      )}
    </div>
  )
}
```

## Error Checklist

```markdown
[ ] All async operations wrapped in try/catch
[ ] User-friendly error messages (no stack traces)
[ ] Errors logged with context
[ ] Error boundaries around major UI sections
[ ] Retry available for transient errors
[ ] Loading/error states in all data components
[ ] Form validation errors shown inline
[ ] API errors include status codes
```

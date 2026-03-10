---
name: server-actions
description: Use when writing Next.js Server Actions. Form handling, validation, revalidation, mutations. Triggers on: server action, use server, form action, revalidatePath, revalidateTag, mutation.
version: 1.0.0
---

# Server Actions (2026)

> **Priority:** CRITICAL | **Auto-Load:** On server action, mutation work
> **Triggers:** server action, use server, mutation, form action

---

## ⚠️ SECURITY ALERT: CVE-2025-29927

**Never rely solely on middleware for authentication!**

The critical CVE-2025-29927 (CVSS 9.1) vulnerability showed that middleware-based authentication can be bypassed with a single HTTP header (`x-middleware-subrequest`).

**Required versions:** Next.js 15.2.3+, 14.2.25+, 13.5.9+, 12.3.5+

### New Security Model (2026)

```
❌ OLD: Middleware → Route Handler (UNSAFE)
✅ NEW: Middleware → DAL → Database (Defense in Depth)
```

Every data access must verify authentication independently.

---

## Data Access Layer (DAL) Pattern

The DAL centralizes all data operations with built-in auth checks.

### Structure

```
lib/
├── dal/
│   ├── index.ts       # Exports all DAL functions
│   ├── users.ts       # User operations
│   ├── projects.ts    # Project operations
│   └── auth.ts        # Auth verification
```

### Auth Verification (Memoized)

```typescript
// lib/dal/auth.ts
import { auth } from '@clerk/nextjs/server'
import { cache } from 'react'
import { redirect } from 'next/navigation'

// Memoized per-request (React cache)
export const verifySession = cache(async () => {
  const { userId } = await auth()

  if (!userId) {
    redirect('/sign-in')
  }

  return { userId }
})

// For actions that should throw instead of redirect
export const requireAuth = cache(async () => {
  const { userId } = await auth()

  if (!userId) {
    throw new Error('Unauthorized')
  }

  return { userId }
})
```

### DAL Functions

```typescript
// lib/dal/projects.ts
import { db } from '@/lib/db'
import { verifySession } from './auth'

export async function getProjects() {
  const { userId } = await verifySession()

  return db.project.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  })
}

export async function getProject(id: string) {
  const { userId } = await verifySession()

  const project = await db.project.findUnique({
    where: { id },
  })

  // BOLA check - verify ownership
  if (!project || project.userId !== userId) {
    throw new Error('Not found')
  }

  return project
}

export async function createProject(data: CreateProjectInput) {
  const { userId } = await verifySession()

  return db.project.create({
    data: {
      ...data,
      userId,
    },
  })
}
```

---

## Server Action Pattern (2026)

### Complete Pattern with All Security Checks

```typescript
// actions/projects.ts
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'
import { requireAuth } from '@/lib/dal/auth'
import { ratelimit } from '@/lib/ratelimit'
import { db } from '@/lib/db'

// 1. Schema with explicit allowlist (OWASP API3)
const CreateProjectSchema = z.object({
  name: z.string().min(2).max(100),
  description: z.string().max(500).optional(),
  // NEVER include: id, userId, isAdmin, etc.
})

// 2. Return type
type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string; field?: string }

// 3. Action implementation
export async function createProject(
  input: z.infer<typeof CreateProjectSchema>
): Promise<ActionResult<{ id: string }>> {
  try {
    // 4. Auth check (OWASP API2)
    const { userId } = await requireAuth()

    // 5. Rate limiting (OWASP API4)
    const { success: allowed } = await ratelimit.limit(userId)
    if (!allowed) {
      return { success: false, error: 'Too many requests' }
    }

    // 6. Validate input (OWASP API3)
    const parsed = CreateProjectSchema.safeParse(input)
    if (!parsed.success) {
      const error = parsed.error.errors[0]
      return {
        success: false,
        error: error.message,
        field: error.path[0] as string,
      }
    }

    // 7. Execute with ownership (OWASP API1)
    const project = await db.project.create({
      data: {
        ...parsed.data,
        userId,
      },
    })

    // 8. Revalidate cache
    revalidatePath('/projects')

    return { success: true, data: { id: project.id } }

  } catch (error) {
    // 9. Safe error (don't leak internals)
    console.error('createProject error:', error)
    return { success: false, error: 'Failed to create project' }
  }
}
```

### Update Action with Ownership Check

```typescript
'use server'

const UpdateProjectSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(2).max(100).optional(),
  description: z.string().max(500).optional(),
})

export async function updateProject(
  input: z.infer<typeof UpdateProjectSchema>
): Promise<ActionResult<{ id: string }>> {
  try {
    const { userId } = await requireAuth()

    // Rate limit
    const { success: allowed } = await ratelimit.limit(userId)
    if (!allowed) {
      return { success: false, error: 'Too many requests' }
    }

    // Validate
    const parsed = UpdateProjectSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.errors[0].message }
    }

    // BOLA check - verify ownership BEFORE update
    const existing = await db.project.findUnique({
      where: { id: parsed.data.id },
      select: { userId: true },
    })

    if (!existing || existing.userId !== userId) {
      return { success: false, error: 'Project not found' }
    }

    // Update
    const project = await db.project.update({
      where: { id: parsed.data.id },
      data: {
        name: parsed.data.name,
        description: parsed.data.description,
      },
    })

    revalidatePath('/projects')
    revalidatePath(`/projects/${project.id}`)

    return { success: true, data: { id: project.id } }

  } catch (error) {
    console.error('updateProject error:', error)
    return { success: false, error: 'Failed to update project' }
  }
}
```

### Delete Action

```typescript
'use server'

export async function deleteProject(
  id: string
): Promise<ActionResult<null>> {
  try {
    const { userId } = await requireAuth()

    // BOLA check
    const existing = await db.project.findUnique({
      where: { id },
      select: { userId: true },
    })

    if (!existing || existing.userId !== userId) {
      return { success: false, error: 'Project not found' }
    }

    await db.project.delete({ where: { id } })

    revalidatePath('/projects')

    return { success: true, data: null }

  } catch (error) {
    console.error('deleteProject error:', error)
    return { success: false, error: 'Failed to delete project' }
  }
}
```

---

## Form Integration

### With React Hook Form

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useTransition } from 'react'
import { createProject } from '@/actions/projects'

const schema = z.object({
  name: z.string().min(2),
  description: z.string().optional(),
})

export function CreateProjectForm() {
  const [isPending, startTransition] = useTransition()

  const form = useForm({
    resolver: zodResolver(schema),
    defaultValues: { name: '', description: '' },
  })

  const onSubmit = (data: z.infer<typeof schema>) => {
    startTransition(async () => {
      const result = await createProject(data)

      if (result.success) {
        form.reset()
        toast.success('Project created!')
      } else {
        if (result.field) {
          form.setError(result.field, { message: result.error })
        } else {
          toast.error(result.error)
        }
      }
    })
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* form fields */}
      <button disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Project'}
      </button>
    </form>
  )
}
```

### With useActionState (React 19)

```typescript
'use client'

import { useActionState } from 'react'
import { createProject } from '@/actions/projects'

export function CreateProjectForm() {
  const [state, action, isPending] = useActionState(
    async (prevState: any, formData: FormData) => {
      const result = await createProject({
        name: formData.get('name') as string,
        description: formData.get('description') as string,
      })
      return result
    },
    null
  )

  return (
    <form action={action}>
      <input name="name" required />
      <textarea name="description" />
      <button disabled={isPending}>Create</button>
      {state?.error && <p className="text-red-500">{state.error}</p>}
    </form>
  )
}
```

---

## Security Checklist

```markdown
Every Server Action MUST have:
[ ] 'use server' directive at top
[ ] Auth check via DAL (not middleware alone)
[ ] Rate limiting
[ ] Zod validation with explicit allowlist
[ ] BOLA check (ownership verification)
[ ] Safe error messages (no internals leaked)
[ ] Try/catch wrapper
[ ] Proper return type

NEVER in Server Actions:
[ ] Trust client-provided IDs without ownership check
[ ] Use direct object spread from input
[ ] Return raw error messages/stack traces
[ ] Skip auth check
[ ] Accept fields like userId, isAdmin from input
```

---

## Output Encoding (XSS Prevention)

Context-aware encoding prevents XSS attacks when returning data to the client.

### HTML Context Encoding

```typescript
// lib/encoding.ts
import DOMPurify from 'isomorphic-dompurify'

// For plain text that will be rendered in HTML
export function encodeHTML(str: string): string {
  const htmlEntities: Record<string, string> = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
  }
  return str.replace(/[&<>"'/]/g, (char) => htmlEntities[char])
}

// For user-generated HTML (markdown, rich text)
export function sanitizeHTML(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'code', 'pre'],
    ALLOWED_ATTR: ['href', 'target', 'rel'],
    ALLOW_DATA_ATTR: false,
  })
}

// For URLs in attributes
export function encodeURLComponent(str: string): string {
  return encodeURIComponent(str)
}

// For JSON in script tags
export function encodeJSON(obj: unknown): string {
  return JSON.stringify(obj)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
}
```

### Server Action with Output Encoding

```typescript
'use server'

import { encodeHTML, sanitizeHTML } from '@/lib/encoding'

const CreateCommentSchema = z.object({
  postId: z.string().uuid(),
  content: z.string().min(1).max(5000),
  allowHTML: z.boolean().optional(),
})

export async function createComment(
  input: z.infer<typeof CreateCommentSchema>
): Promise<ActionResult<{ id: string; content: string }>> {
  try {
    const { userId } = await requireAuth()

    const parsed = CreateCommentSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: 'Invalid input' }
    }

    // Encode content based on context
    const safeContent = parsed.data.allowHTML
      ? sanitizeHTML(parsed.data.content)  // Rich text - sanitize
      : encodeHTML(parsed.data.content)    // Plain text - encode

    const comment = await db.comment.create({
      data: {
        postId: parsed.data.postId,
        content: safeContent,  // Store encoded/sanitized
        userId,
      },
    })

    return {
      success: true,
      data: { id: comment.id, content: comment.content },
    }

  } catch (error) {
    console.error('createComment error:', error)
    return { success: false, error: 'Failed to create comment' }
  }
}
```

### Response Encoding in API Routes

```typescript
// app/api/posts/[id]/route.ts
import { encodeJSON } from '@/lib/encoding'

export async function GET(req: Request, { params }: { params: { id: string } }) {
  const post = await db.post.findUnique({ where: { id: params.id } })

  if (!post) {
    return Response.json({ error: 'Not found' }, { status: 404 })
  }

  // Safe JSON response (prevents JSON injection in HTML contexts)
  return new Response(encodeJSON(post), {
    headers: {
      'Content-Type': 'application/json',
      'X-Content-Type-Options': 'nosniff',
    },
  })
}
```

### Client-Side Safe Rendering

```typescript
// components/Comment.tsx
'use client'

import DOMPurify from 'dompurify'

interface CommentProps {
  content: string
  isHTML?: boolean
}

export function Comment({ content, isHTML }: CommentProps) {
  if (isHTML) {
    // Content was sanitized on server, but double-sanitize on client
    const safeHTML = DOMPurify.sanitize(content)
    return <div dangerouslySetInnerHTML={{ __html: safeHTML }} />
  }

  // Plain text - React auto-escapes
  return <p>{content}</p>
}
```

### Output Encoding Checklist

```markdown
Output Encoding:
[ ] HTML entities encoded for text content
[ ] User HTML sanitized with DOMPurify (allowlist tags)
[ ] URLs encoded with encodeURIComponent
[ ] JSON responses encoded (no raw < > &)
[ ] Content-Type headers set correctly
[ ] X-Content-Type-Options: nosniff header set
[ ] dangerouslySetInnerHTML only with sanitized content
```

---

## Anti-Patterns

| Anti-Pattern | Risk | Solution |
|--------------|------|----------|
| Middleware-only auth | CVE-2025-29927 bypass | DAL with per-action auth |
| Direct object spread | Mass assignment | Explicit allowlist (Zod) |
| No ownership check | BOLA | Always verify resource.userId |
| Raw error messages | Info leakage | Generic client errors |
| No rate limiting | DoS, abuse | Upstash ratelimit |
| No output encoding | XSS | Context-aware encoding |
| Raw user HTML | XSS | DOMPurify sanitization |

---

## Related Skills

- `rate-limiting` - Rate limiting patterns
- `zod` - Schema validation
- `owasp-api-2023` - API security checklist
- `middleware-2026` - Middleware patterns

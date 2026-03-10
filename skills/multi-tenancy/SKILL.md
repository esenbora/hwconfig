---
name: multi-tenancy
description: Use when building SaaS with multiple organizations or tenants. Row-level security, tenant isolation. Triggers on: multi-tenant, tenant, organization, saas, rls, row level security, workspace.
version: 1.0.0
triggers: ["multi-tenant", "saas", "tenant", "organization", "workspace", "rls"]
---

# Multi-Tenancy (2026)

> Critical patterns for SaaS applications with multiple tenants/organizations.
> **Data leakage between tenants = catastrophic security breach.**

---

## 🚨 WHY THIS MATTERS

```
Multi-tenancy failures cause:
❌ Data leakage (Tenant A sees Tenant B's data)
❌ Privilege escalation (User joins wrong organization)
❌ Cache poisoning (Tenant A gets Tenant B's cached data)
❌ Compliance violations (GDPR, SOC2 failures)
```

---

## Tenancy Models

| Model | Isolation | Cost | Complexity |
|-------|-----------|------|------------|
| **Shared DB, Shared Schema** | Low (RLS) | $ | Low |
| **Shared DB, Separate Schema** | Medium | $$ | Medium |
| **Separate DB per Tenant** | High | $$$ | High |

**Recommendation:** Shared DB with Row-Level Security (RLS) for most SaaS.

---

## Data Access Layer with Tenant Context

```typescript
// lib/dal/tenant.ts
import { auth } from '@clerk/nextjs/server'
import { cache } from 'react'
import { db } from '@/lib/db'

// Get current tenant context
export const getTenantContext = cache(async () => {
  const { userId, orgId } = await auth()

  if (!userId) throw new Error('Unauthorized')

  // orgId is the tenant ID in Clerk
  // For personal accounts, use a derived tenant ID
  const tenantId = orgId || `user_${userId}`

  return { userId, tenantId }
})

// ALWAYS use this for queries
export const tenantDb = {
  // Projects scoped to tenant
  project: {
    findMany: async (args?: any) => {
      const { tenantId } = await getTenantContext()
      return db.project.findMany({
        ...args,
        where: {
          ...args?.where,
          tenantId,  // ALWAYS filter by tenant
        },
      })
    },

    findUnique: async (args: { where: { id: string } }) => {
      const { tenantId } = await getTenantContext()
      const project = await db.project.findUnique(args)

      // BOLA check: Verify tenant ownership
      if (project && project.tenantId !== tenantId) {
        throw new Error('Not found')  // Don't reveal existence
      }

      return project
    },

    create: async (args: { data: any }) => {
      const { tenantId, userId } = await getTenantContext()
      return db.project.create({
        ...args,
        data: {
          ...args.data,
          tenantId,  // Server sets tenant
          createdBy: userId,
        },
      })
    },

    update: async (args: { where: { id: string }; data: any }) => {
      const { tenantId } = await getTenantContext()

      // Verify ownership before update
      const existing = await db.project.findUnique({
        where: { id: args.where.id },
      })

      if (!existing || existing.tenantId !== tenantId) {
        throw new Error('Not found')
      }

      return db.project.update(args)
    },

    delete: async (args: { where: { id: string } }) => {
      const { tenantId } = await getTenantContext()

      // Verify ownership before delete
      const existing = await db.project.findUnique({
        where: { id: args.where.id },
      })

      if (!existing || existing.tenantId !== tenantId) {
        throw new Error('Not found')
      }

      return db.project.delete(args)
    },
  },
}
```

---

## Database Schema with Tenant

```typescript
// prisma/schema.prisma
model Tenant {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique
  plan      String   @default("free")
  createdAt DateTime @default(now())

  // Relations
  projects  Project[]
  users     TenantUser[]
  settings  TenantSettings?
}

model TenantUser {
  id        String   @id @default(cuid())
  userId    String   // Clerk user ID
  tenantId  String
  role      String   @default("member")  // owner, admin, member
  createdAt DateTime @default(now())

  tenant    Tenant   @relation(fields: [tenantId], references: [id])

  @@unique([userId, tenantId])
  @@index([userId])
  @@index([tenantId])
}

model Project {
  id        String   @id @default(cuid())
  name      String
  tenantId  String   // REQUIRED: Every table has tenantId
  createdBy String
  createdAt DateTime @default(now())

  tenant    Tenant   @relation(fields: [tenantId], references: [id])

  @@index([tenantId])  // REQUIRED: Index for tenant queries
}
```

---

## PostgreSQL Row-Level Security (RLS)

```sql
-- Enable RLS on table
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their tenant's data
CREATE POLICY tenant_isolation ON projects
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant_id')::text);

-- Set tenant context before queries (in application)
-- SET LOCAL app.current_tenant_id = 'tenant_123';
```

```typescript
// Using RLS with Prisma
export async function withTenantContext<T>(
  tenantId: string,
  fn: () => Promise<T>
): Promise<T> {
  // Set tenant context for RLS
  await db.$executeRaw`SET LOCAL app.current_tenant_id = ${tenantId}`

  try {
    return await fn()
  } finally {
    // Clear context
    await db.$executeRaw`RESET app.current_tenant_id`
  }
}

// Usage
const projects = await withTenantContext(tenantId, () =>
  db.project.findMany()  // RLS automatically filters
)
```

---

## Tenant-Scoped Caching

```typescript
// lib/cache/tenant.ts
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

// ALWAYS include tenant in cache key
export function tenantCacheKey(tenantId: string, key: string): string {
  return `tenant:${tenantId}:${key}`
}

export async function getTenantCache<T>(
  tenantId: string,
  key: string
): Promise<T | null> {
  return redis.get<T>(tenantCacheKey(tenantId, key))
}

export async function setTenantCache<T>(
  tenantId: string,
  key: string,
  value: T,
  ttl = 3600
): Promise<void> {
  await redis.set(tenantCacheKey(tenantId, key), value, { ex: ttl })
}

export async function invalidateTenantCache(
  tenantId: string,
  pattern: string
): Promise<void> {
  const keys = await redis.keys(`tenant:${tenantId}:${pattern}*`)
  if (keys.length > 0) {
    await redis.del(...keys)
  }
}
```

---

## Tenant Switching (Organization Switcher)

```typescript
// app/api/tenant/switch/route.ts
import { auth, clerkClient } from '@clerk/nextjs/server'

export async function POST(req: Request) {
  const { userId } = await auth()
  if (!userId) return new Response('Unauthorized', { status: 401 })

  const { tenantId } = await req.json()

  // Verify user is member of tenant
  const membership = await db.tenantUser.findUnique({
    where: {
      userId_tenantId: { userId, tenantId }
    }
  })

  if (!membership) {
    return new Response('Not a member of this organization', { status: 403 })
  }

  // Update active organization in Clerk
  await clerkClient.users.updateUser(userId, {
    publicMetadata: { activeTenantId: tenantId }
  })

  return Response.json({ success: true })
}
```

---

## Cross-Tenant Query Prevention

```typescript
// middleware/tenant-guard.ts
import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@clerk/nextjs/server'

export async function validateTenantAccess(
  req: NextRequest,
  resourceTenantId: string
): Promise<boolean> {
  const { userId, orgId } = await auth()

  if (!userId) return false

  const currentTenantId = orgId || `user_${userId}`

  // Log suspicious cross-tenant attempts
  if (resourceTenantId !== currentTenantId) {
    console.warn('Cross-tenant access attempt:', {
      userId,
      currentTenant: currentTenantId,
      attemptedTenant: resourceTenantId,
      path: req.nextUrl.pathname,
      timestamp: new Date().toISOString(),
    })
    return false
  }

  return true
}
```

---

## Audit Logging for Compliance

```typescript
// lib/audit/tenant.ts
export async function logTenantAction(params: {
  tenantId: string
  userId: string
  action: string
  resource: string
  resourceId: string
  details?: Record<string, any>
}) {
  await db.auditLog.create({
    data: {
      ...params,
      ip: headers().get('x-forwarded-for') || 'unknown',
      userAgent: headers().get('user-agent') || 'unknown',
      createdAt: new Date(),
    }
  })
}

// Usage in server action
export async function deleteProject(projectId: string) {
  const { userId, tenantId } = await getTenantContext()

  await logTenantAction({
    tenantId,
    userId,
    action: 'DELETE',
    resource: 'project',
    resourceId: projectId,
  })

  // ... delete logic
}
```

---

## Server Action Pattern

```typescript
'use server'

import { z } from 'zod'
import { getTenantContext, tenantDb } from '@/lib/dal/tenant'
import { ratelimit } from '@/lib/ratelimit'

const CreateProjectSchema = z.object({
  name: z.string().min(1).max(100),
  // NEVER allow tenantId from client
})

export async function createProject(input: z.infer<typeof CreateProjectSchema>) {
  try {
    // 1. Get tenant context (includes auth)
    const { userId, tenantId } = await getTenantContext()

    // 2. Rate limit per tenant
    const { success } = await ratelimit.limit(`tenant:${tenantId}`)
    if (!success) return { success: false, error: 'Too many requests' }

    // 3. Validate
    const parsed = CreateProjectSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.errors[0].message }
    }

    // 4. Create with tenant (server sets tenantId)
    const project = await tenantDb.project.create({
      data: parsed.data
    })

    return { success: true, data: { id: project.id } }

  } catch (error) {
    console.error('Create project error:', error)
    return { success: false, error: 'Failed to create' }
  }
}
```

---

## Security Checklist

```
Data Isolation:
□ Every table has tenantId column
□ Every query filters by tenantId
□ RLS enabled on PostgreSQL (if using)
□ Index on tenantId for all tables

Access Control:
□ Tenant context from auth, never from client
□ BOLA check on every resource access
□ Cross-tenant access logged and blocked
□ Organization membership verified

Caching:
□ Cache keys include tenantId
□ No shared cache between tenants
□ Cache invalidation per tenant

Compliance:
□ Audit logging per tenant
□ Data export per tenant
□ Tenant deletion (GDPR) supported
```

---

## Anti-Patterns

```typescript
// ❌ WRONG: Trust client tenantId
const { tenantId } = await req.json()  // Attacker can set any tenant!

// ❌ WRONG: No tenant filter
const projects = await db.project.findMany()  // Returns ALL tenants!

// ❌ WRONG: Shared cache key
await redis.set(`projects:${userId}`, data)  // Cache collision!

// ❌ WRONG: Tenant in URL only
// /api/tenants/123/projects - Can be manipulated

// ✅ CORRECT: Tenant from auth session
const { tenantId } = await getTenantContext()

// ✅ CORRECT: Always filter
const projects = await db.project.findMany({
  where: { tenantId }
})

// ✅ CORRECT: Tenant-scoped cache
await redis.set(`tenant:${tenantId}:projects`, data)
```

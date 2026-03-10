---
name: feature-flags
description: Use when implementing feature toggles, gradual rollouts, A/B testing, or kill switches. LaunchDarkly, Flagsmith, custom flags. Triggers on: feature flag, feature toggle, rollout, a/b test, experiment, kill switch, canary.
version: 1.0.0
---

# Feature Flags

> Ship code without shipping features. Control releases, not deployments.

---

## Quick Reference

```typescript
// Check flag
if (await flags.isEnabled('new-checkout')) {
  return <NewCheckout />
}

// Gradual rollout
const variant = await flags.getVariant('checkout-experiment', userId)

// Kill switch
if (await flags.isEnabled('maintenance-mode')) {
  return <MaintenancePage />
}
```

---

## Implementation Patterns

### 1. Simple Boolean Flags

```typescript
// lib/feature-flags.ts
type FeatureFlag = {
  enabled: boolean
  percentage?: number  // For gradual rollout
  userIds?: string[]   // For specific users
}

const flags: Record<string, FeatureFlag> = {
  'new-dashboard': { enabled: false },
  'dark-mode': { enabled: true },
  'beta-features': { enabled: false, userIds: ['user_123'] },
  'new-pricing': { enabled: false, percentage: 10 },
}

export function isEnabled(flag: string, userId?: string): boolean {
  const config = flags[flag]
  if (!config) return false

  // Check user-specific override
  if (userId && config.userIds?.includes(userId)) {
    return true
  }

  // Check percentage rollout
  if (config.percentage !== undefined && userId) {
    const hash = hashUserId(userId, flag)
    return hash < config.percentage
  }

  return config.enabled
}

// Consistent hashing for gradual rollout
function hashUserId(userId: string, flag: string): number {
  const str = `${userId}:${flag}`
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i)
    hash |= 0
  }
  return Math.abs(hash) % 100
}
```

### 2. Environment-Based Flags

```typescript
// lib/flags.ts
const flags = {
  // Always on in development
  'debug-panel': process.env.NODE_ENV === 'development',

  // Environment variable controlled
  'new-api': process.env.FEATURE_NEW_API === 'true',

  // Staging only
  'experimental': process.env.VERCEL_ENV === 'preview',
}

export function getFlag(name: keyof typeof flags): boolean {
  return flags[name] ?? false
}
```

### 3. Database-Backed Flags

```typescript
// lib/feature-flags.ts
import { db } from '@/lib/db'
import { unstable_cache } from 'next/cache'

type Flag = {
  name: string
  enabled: boolean
  percentage: number | null
  allowedUserIds: string[]
  metadata: Record<string, any>
}

export const getFlags = unstable_cache(
  async () => {
    const flags = await db.featureFlag.findMany({
      where: { deletedAt: null }
    })
    return new Map(flags.map(f => [f.name, f]))
  },
  ['feature-flags'],
  { revalidate: 60 } // Cache for 1 minute
)

export async function isEnabled(name: string, userId?: string): Promise<boolean> {
  const flags = await getFlags()
  const flag = flags.get(name)

  if (!flag) return false
  if (!flag.enabled) return false

  // Check user allowlist
  if (userId && flag.allowedUserIds.includes(userId)) {
    return true
  }

  // Check percentage
  if (flag.percentage !== null && userId) {
    return hashUser(userId, name) < flag.percentage
  }

  return flag.enabled
}
```

### 4. React Hook for Flags

```typescript
// hooks/use-feature-flag.ts
'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@clerk/nextjs'

export function useFeatureFlag(flagName: string): boolean {
  const { userId } = useAuth()
  const [enabled, setEnabled] = useState(false)

  useEffect(() => {
    async function checkFlag() {
      const res = await fetch(`/api/flags/${flagName}`)
      const { enabled } = await res.json()
      setEnabled(enabled)
    }
    checkFlag()
  }, [flagName, userId])

  return enabled
}

// Usage
function Dashboard() {
  const showNewWidget = useFeatureFlag('new-widget')

  return (
    <div>
      {showNewWidget ? <NewWidget /> : <OldWidget />}
    </div>
  )
}
```

### 5. Server Component Flags

```typescript
// app/dashboard/page.tsx
import { isEnabled } from '@/lib/feature-flags'
import { auth } from '@clerk/nextjs'

export default async function DashboardPage() {
  const { userId } = auth()

  const showNewLayout = await isEnabled('new-dashboard-layout', userId)

  if (showNewLayout) {
    return <NewDashboardLayout />
  }

  return <CurrentDashboardLayout />
}
```

---

## A/B Testing Pattern

```typescript
// lib/experiments.ts
type Variant = 'control' | 'treatment-a' | 'treatment-b'

type Experiment = {
  name: string
  variants: {
    [key in Variant]?: number // percentage
  }
}

const experiments: Record<string, Experiment> = {
  'checkout-flow': {
    name: 'checkout-flow',
    variants: {
      control: 50,
      'treatment-a': 25,
      'treatment-b': 25,
    },
  },
}

export function getVariant(experimentName: string, userId: string): Variant {
  const experiment = experiments[experimentName]
  if (!experiment) return 'control'

  const hash = hashUser(userId, experimentName)
  let cumulative = 0

  for (const [variant, percentage] of Object.entries(experiment.variants)) {
    cumulative += percentage!
    if (hash < cumulative) {
      return variant as Variant
    }
  }

  return 'control'
}

// Track experiment exposure
export async function trackExposure(
  experimentName: string,
  variant: Variant,
  userId: string
) {
  await analytics.track('Experiment Exposure', {
    experiment: experimentName,
    variant,
    userId,
  })
}
```

---

## Gradual Rollout Strategy

```typescript
// Rollout schedule example
const rolloutSchedule = {
  'new-feature': [
    { date: '2024-01-15', percentage: 1 },   // Canary
    { date: '2024-01-16', percentage: 5 },   // Early adopters
    { date: '2024-01-17', percentage: 25 },  // Wider beta
    { date: '2024-01-18', percentage: 50 },  // Half
    { date: '2024-01-20', percentage: 100 }, // Full rollout
  ],
}

// Automated rollout with monitoring
async function executeRollout(flagName: string) {
  const schedule = rolloutSchedule[flagName]

  for (const stage of schedule) {
    await updateFlagPercentage(flagName, stage.percentage)

    // Monitor for errors
    const errorRate = await getErrorRate(flagName, '1h')
    if (errorRate > 0.01) {
      // Rollback on high error rate
      await updateFlagPercentage(flagName, 0)
      await alertTeam(`Rollback: ${flagName} due to ${errorRate * 100}% errors`)
      return
    }

    // Wait for next stage
    await waitUntil(stage.date)
  }
}
```

---

## Kill Switches

```typescript
// Critical kill switches for production
const killSwitches = {
  // Disable feature entirely
  'payments-enabled': true,

  // Maintenance mode
  'maintenance-mode': false,

  // Rate limiting bypass
  'rate-limit-enabled': true,

  // External service fallbacks
  'use-backup-api': false,
}

// Middleware for kill switches
export function middleware(request: NextRequest) {
  // Quick maintenance mode check
  if (killSwitches['maintenance-mode']) {
    return NextResponse.rewrite(new URL('/maintenance', request.url))
  }

  // Disable payments
  if (!killSwitches['payments-enabled'] &&
      request.nextUrl.pathname.startsWith('/api/payments')) {
    return NextResponse.json(
      { error: 'Payments temporarily disabled' },
      { status: 503 }
    )
  }

  return NextResponse.next()
}
```

---

## Flag Management API

```typescript
// app/api/admin/flags/route.ts
import { auth } from '@clerk/nextjs'
import { db } from '@/lib/db'

export async function GET() {
  const { userId } = auth()
  if (!await isAdmin(userId)) {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  const flags = await db.featureFlag.findMany()
  return Response.json(flags)
}

export async function PUT(request: Request) {
  const { userId } = auth()
  if (!await isAdmin(userId)) {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  const { name, enabled, percentage } = await request.json()

  // Audit log
  await db.auditLog.create({
    data: {
      action: 'flag_updated',
      userId,
      details: { name, enabled, percentage },
    },
  })

  const flag = await db.featureFlag.update({
    where: { name },
    data: { enabled, percentage },
  })

  // Invalidate cache
  revalidateTag('feature-flags')

  return Response.json(flag)
}
```

---

## Best Practices

### Naming Convention

```
<scope>.<feature>.<variant>

Examples:
- checkout.new-flow
- dashboard.widget.v2
- api.rate-limit.strict
- experiment.pricing.premium-highlight
```

### Flag Lifecycle

```
1. Created (disabled)
2. Testing (enabled for devs)
3. Canary (1% of users)
4. Gradual Rollout (5% → 25% → 50% → 100%)
5. Fully Enabled
6. Cleanup (remove flag, keep feature)
```

### Technical Debt Prevention

```typescript
// Track flag age and usage
type FlagMetadata = {
  createdAt: Date
  lastChecked: Date
  owner: string
  jiraTicket?: string
  cleanupDate?: Date
}

// Alert on stale flags
async function flagCleanupReminder() {
  const staleFlags = await db.featureFlag.findMany({
    where: {
      createdAt: { lt: subMonths(new Date(), 3) },
      enabled: true,
      percentage: 100, // Fully rolled out
    },
  })

  for (const flag of staleFlags) {
    await notifyOwner(flag.owner, `Flag "${flag.name}" is ready for cleanup`)
  }
}
```

---

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Nest feature flags deeply | Keep flags at top level |
| Leave flags forever | Clean up after full rollout |
| No monitoring during rollout | Alert on error rate changes |
| Test only in production | Test in staging first |
| Manual percentage changes | Use automated rollout |
| No audit trail | Log all flag changes |

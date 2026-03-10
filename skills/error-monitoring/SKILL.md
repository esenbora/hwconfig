---
name: error-monitoring
description: Use when setting up error tracking or monitoring. Sentry, error context, breadcrumbs. Triggers on: sentry, error tracking, monitoring, error monitoring, breadcrumbs, crash reporting, bug tracking.
version: 1.0.0
triggers: ["sentry", "error tracking", "monitoring", "alerting", "error budget"]
---

# Error Monitoring (2026)

> Comprehensive error monitoring, alerting, and operational response patterns.
> **Unmonitored errors = invisible failures = lost users.**

---

## 🚨 WHY THIS MATTERS

```
Poor error monitoring causes:
❌ Silent failures (errors nobody sees)
❌ Alert fatigue (too many non-actionable alerts)
❌ Slow response (no severity classification)
❌ Repeated incidents (no error budget tracking)
```

---

## Sentry Setup (Next.js 2026)

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // Performance monitoring
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // Session replay for debugging
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  // Environment tagging
  environment: process.env.NODE_ENV,
  release: process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_SHA,

  // Filter noisy errors
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    'Non-Error promise rejection',
    /Loading chunk \d+ failed/,
  ],

  // Enrich errors with context
  beforeSend(event, hint) {
    // Filter out non-actionable errors
    if (event.exception?.values?.[0]?.type === 'ChunkLoadError') {
      return null  // Don't send chunk load errors
    }
    return event
  },

  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],
})
```

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 0.1,
  environment: process.env.NODE_ENV,
  release: process.env.VERCEL_GIT_COMMIT_SHA,

  // Capture unhandled promise rejections
  integrations: [
    Sentry.prismaIntegration(),  // Track slow queries
  ],
})
```

---

## Error Severity Classification

```typescript
// lib/monitoring/severity.ts
export enum ErrorSeverity {
  CRITICAL = 'critical',   // Page oncall immediately
  HIGH = 'high',           // Alert Slack, fix within 1 hour
  MEDIUM = 'medium',       // Fix within 24 hours
  LOW = 'low',             // Fix in next sprint
  INFO = 'info',           // Log only, no action
}

export function classifyError(error: Error, context?: ErrorContext): ErrorSeverity {
  // Payment/financial errors = CRITICAL
  if (context?.domain === 'payment' || error.message.includes('payment')) {
    return ErrorSeverity.CRITICAL
  }

  // Auth errors = HIGH
  if (context?.domain === 'auth' || error.message.includes('auth')) {
    return ErrorSeverity.HIGH
  }

  // Database errors = HIGH
  if (error.name === 'PrismaClientKnownRequestError') {
    return ErrorSeverity.HIGH
  }

  // Rate limit = MEDIUM (expected behavior)
  if (error.message.includes('rate limit')) {
    return ErrorSeverity.MEDIUM
  }

  // Validation errors = LOW (user error)
  if (error.name === 'ValidationError') {
    return ErrorSeverity.LOW
  }

  // Default
  return ErrorSeverity.MEDIUM
}
```

---

## Structured Error Capture

```typescript
// lib/monitoring/capture.ts
import * as Sentry from '@sentry/nextjs'

interface ErrorContext {
  userId?: string
  tenantId?: string
  domain?: 'payment' | 'auth' | 'api' | 'background' | 'ui'
  action?: string
  metadata?: Record<string, any>
}

export function captureError(error: Error, context?: ErrorContext) {
  const severity = classifyError(error, context)

  Sentry.withScope((scope) => {
    // Set severity level
    scope.setLevel(mapSeverityToSentryLevel(severity))

    // Set user context
    if (context?.userId) {
      scope.setUser({ id: context.userId })
    }

    // Set tags for filtering
    scope.setTags({
      domain: context?.domain || 'unknown',
      action: context?.action || 'unknown',
      severity,
    })

    // Add extra context
    if (context?.metadata) {
      scope.setExtras(context.metadata)
    }

    // Set tenant for multi-tenant apps
    if (context?.tenantId) {
      scope.setTag('tenant_id', context.tenantId)
    }

    Sentry.captureException(error)
  })

  // Trigger immediate alert for critical errors
  if (severity === ErrorSeverity.CRITICAL) {
    triggerPagerDuty(error, context)
  }
}

function mapSeverityToSentryLevel(severity: ErrorSeverity): Sentry.SeverityLevel {
  switch (severity) {
    case ErrorSeverity.CRITICAL: return 'fatal'
    case ErrorSeverity.HIGH: return 'error'
    case ErrorSeverity.MEDIUM: return 'warning'
    case ErrorSeverity.LOW: return 'info'
    case ErrorSeverity.INFO: return 'debug'
  }
}
```

---

## Alert Rules Configuration

```typescript
// Alert rules (configure in Sentry UI or via API)
const alertRules = {
  // CRITICAL: Page immediately
  paymentFailure: {
    conditions: [
      { type: 'event.tag', key: 'domain', value: 'payment' },
      { type: 'event.level', value: 'fatal' },
    ],
    actions: [
      { type: 'pagerduty', service: 'production-oncall' },
      { type: 'slack', channel: '#incidents' },
    ],
    frequency: 0,  // Every occurrence
  },

  // HIGH: Alert Slack
  authErrors: {
    conditions: [
      { type: 'event.tag', key: 'domain', value: 'auth' },
      { type: 'event.frequency', value: 10, interval: '1h' },
    ],
    actions: [
      { type: 'slack', channel: '#alerts' },
    ],
    frequency: 300,  // Max once per 5 min
  },

  // MEDIUM: Daily digest
  apiErrors: {
    conditions: [
      { type: 'event.tag', key: 'domain', value: 'api' },
      { type: 'event.frequency', value: 100, interval: '24h' },
    ],
    actions: [
      { type: 'slack', channel: '#engineering' },
    ],
    frequency: 86400,  // Daily
  },

  // Error spike detection
  errorSpike: {
    conditions: [
      { type: 'event.frequency', comparison: 'percent_change', value: 200, interval: '1h' },
    ],
    actions: [
      { type: 'slack', channel: '#alerts' },
      { type: 'pagerduty', service: 'production-oncall' },
    ],
    frequency: 300,
  },
}
```

---

## Error Budget Tracking

```typescript
// lib/monitoring/error-budget.ts
import * as Sentry from '@sentry/nextjs'

interface ErrorBudget {
  target: number      // e.g., 99.9% = 0.1% error budget
  window: number      // Rolling window in days
  currentRate: number // Current error rate
  remaining: number   // Budget remaining as percentage
}

export async function getErrorBudget(): Promise<ErrorBudget> {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)

  // Query Sentry API for error metrics
  const stats = await fetch(
    `https://sentry.io/api/0/projects/${ORG}/${PROJECT}/stats/`,
    {
      headers: { Authorization: `Bearer ${SENTRY_AUTH_TOKEN}` },
      body: JSON.stringify({
        stat: 'received',
        start: thirtyDaysAgo.toISOString(),
        end: new Date().toISOString(),
        resolution: '1d',
      }),
    }
  )

  const data = await stats.json()
  const totalRequests = data.totalRequests
  const totalErrors = data.totalErrors
  const errorRate = totalErrors / totalRequests

  const target = 0.999  // 99.9% availability
  const budgetTotal = 1 - target  // 0.1%
  const budgetUsed = errorRate
  const budgetRemaining = Math.max(0, budgetTotal - budgetUsed)

  return {
    target,
    window: 30,
    currentRate: errorRate,
    remaining: (budgetRemaining / budgetTotal) * 100,
  }
}

// Cron job to check error budget
export const checkErrorBudget = inngest.createFunction(
  { id: 'check-error-budget' },
  { cron: '0 9 * * *' },  // Daily at 9 AM
  async ({ step }) => {
    const budget = await step.run('get-budget', getErrorBudget)

    if (budget.remaining < 20) {
      await step.run('alert', async () => {
        await sendSlackMessage('#engineering', {
          text: `⚠️ Error budget low: ${budget.remaining.toFixed(1)}% remaining`,
          blocks: [
            {
              type: 'section',
              text: {
                type: 'mrkdwn',
                text: [
                  `*Error Budget Alert*`,
                  `• Current error rate: ${(budget.currentRate * 100).toFixed(3)}%`,
                  `• Budget remaining: ${budget.remaining.toFixed(1)}%`,
                  `• Target SLA: ${(budget.target * 100).toFixed(1)}%`,
                ].join('\n'),
              },
            },
          ],
        })
      })
    }
  }
)
```

---

## Background Job Error Tracking

```typescript
// lib/monitoring/background.ts
import * as Sentry from '@sentry/nextjs'

export function wrapBackgroundJob<T>(
  jobName: string,
  fn: () => Promise<T>
): () => Promise<T> {
  return async () => {
    const transaction = Sentry.startTransaction({
      name: jobName,
      op: 'background.job',
    })

    Sentry.getCurrentHub().configureScope((scope) => {
      scope.setSpan(transaction)
    })

    try {
      const result = await fn()
      transaction.setStatus('ok')
      return result
    } catch (error) {
      transaction.setStatus('internal_error')
      captureError(error as Error, {
        domain: 'background',
        action: jobName,
      })
      throw error
    } finally {
      transaction.finish()
    }
  }
}

// Usage with Inngest
export const processPayment = inngest.createFunction(
  { id: 'process-payment' },
  { event: 'payment/process' },
  wrapBackgroundJob('process-payment', async ({ event }) => {
    // ... payment logic
  })
)
```

---

## Canary Deployment Error Detection

```typescript
// lib/monitoring/canary.ts
export async function checkCanaryHealth(
  canaryVersion: string,
  stableVersion: string
): Promise<{ healthy: boolean; reason?: string }> {
  const canaryErrors = await getErrorRate(canaryVersion, '1h')
  const stableErrors = await getErrorRate(stableVersion, '1h')

  // Canary has 2x error rate = unhealthy
  if (canaryErrors > stableErrors * 2) {
    return {
      healthy: false,
      reason: `Canary error rate (${(canaryErrors * 100).toFixed(2)}%) is 2x stable (${(stableErrors * 100).toFixed(2)}%)`,
    }
  }

  // Canary has new error types
  const canaryErrorTypes = await getUniqueErrorTypes(canaryVersion, '1h')
  const stableErrorTypes = await getUniqueErrorTypes(stableVersion, '24h')
  const newErrors = canaryErrorTypes.filter(e => !stableErrorTypes.includes(e))

  if (newErrors.length > 0) {
    return {
      healthy: false,
      reason: `Canary has ${newErrors.length} new error types: ${newErrors.join(', ')}`,
    }
  }

  return { healthy: true }
}
```

---

## PagerDuty Integration

```typescript
// lib/monitoring/pagerduty.ts
const PAGERDUTY_ROUTING_KEY = process.env.PAGERDUTY_ROUTING_KEY!

export async function triggerPagerDuty(
  error: Error,
  context?: ErrorContext
) {
  await fetch('https://events.pagerduty.com/v2/enqueue', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      routing_key: PAGERDUTY_ROUTING_KEY,
      event_action: 'trigger',
      dedup_key: `${error.name}-${error.message}`.slice(0, 255),
      payload: {
        summary: `[${context?.domain || 'unknown'}] ${error.message}`,
        severity: 'critical',
        source: 'production',
        component: context?.domain,
        custom_details: {
          error_name: error.name,
          error_message: error.message,
          stack: error.stack,
          user_id: context?.userId,
          tenant_id: context?.tenantId,
          action: context?.action,
        },
      },
    }),
  })
}
```

---

## Slack Alert Integration

```typescript
// lib/monitoring/slack.ts
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL!

interface SlackMessage {
  text: string
  blocks?: any[]
}

export async function sendSlackMessage(
  channel: string,
  message: SlackMessage
) {
  await fetch(SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      channel,
      ...message,
    }),
  })
}

// Error alert template
export function formatErrorAlert(error: Error, context?: ErrorContext) {
  return {
    text: `🚨 ${context?.domain || 'Error'}: ${error.message}`,
    blocks: [
      {
        type: 'header',
        text: { type: 'plain_text', text: '🚨 Error Alert' },
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*Domain:*\n${context?.domain || 'unknown'}` },
          { type: 'mrkdwn', text: `*Action:*\n${context?.action || 'unknown'}` },
          { type: 'mrkdwn', text: `*User:*\n${context?.userId || 'anonymous'}` },
          { type: 'mrkdwn', text: `*Tenant:*\n${context?.tenantId || 'n/a'}` },
        ],
      },
      {
        type: 'section',
        text: { type: 'mrkdwn', text: `\`\`\`${error.stack?.slice(0, 500)}\`\`\`` },
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View in Sentry' },
            url: `https://sentry.io/issues/?query=is:unresolved`,
          },
        ],
      },
    ],
  }
}
```

---

## Security Checklist

```
Error Monitoring:
□ Sentry DSN in environment variables (not code)
□ Session replay masks sensitive data
□ Stack traces don't contain secrets
□ User IDs, not emails, in error context
□ PII filtered from error payloads

Alerting:
□ Critical errors page on-call immediately
□ Alert thresholds prevent alert fatigue
□ Deduplication prevents alert storms
□ Escalation paths defined

Operations:
□ Error budget tracked and alerted
□ Canary deployments monitored
□ Background jobs wrapped with monitoring
□ Dashboard shows key metrics
```

---

## Anti-Patterns

```typescript
// ❌ WRONG: No error context
try {
  await doSomething()
} catch (error) {
  Sentry.captureException(error)  // No context!
}

// ❌ WRONG: Sensitive data in errors
captureError(error, {
  metadata: { password: user.password }  // PII exposed!
})

// ❌ WRONG: Alert on every error
if (error) {
  sendSlackMessage('#alerts', error)  // Alert fatigue!
}

// ✅ CORRECT: Structured capture with context
try {
  await processPayment(paymentId)
} catch (error) {
  captureError(error as Error, {
    domain: 'payment',
    action: 'processPayment',
    userId: user.id,
    metadata: { paymentId },  // Not sensitive
  })
}
```

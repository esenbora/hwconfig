---
name: observability
description: Use when adding logging, tracing, or metrics. Structured logging, OpenTelemetry. Triggers on: observability, logging, tracing, metrics, opentelemetry, log, trace, monitor, analytics, telemetry, dashboard.
version: 1.0.0
---

# Observability

Production-grade observability with logs, metrics, traces, and alerts.

## The Three Pillars

### 1. Structured Logging

```typescript
import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
})

// Always structured, never string concatenation
logger.info({ userId, action: 'login' }, 'User logged in')
logger.error({ error, requestId }, 'Payment failed')
```

### 2. Metrics

```typescript
// Key metrics to track
- request_duration_seconds (histogram)
- request_total (counter, by status code)
- active_connections (gauge)
- queue_depth (gauge)
- error_rate (counter)

// Business metrics
- revenue_total
- signups_total
- feature_usage_total
```

### 3. Distributed Tracing

```typescript
import { trace } from '@opentelemetry/api'

const tracer = trace.getTracer('my-service')

async function handleRequest(req: Request) {
  const span = tracer.startSpan('handleRequest')

  try {
    span.setAttribute('user.id', userId)
    const result = await processRequest(req)
    span.setStatus({ code: SpanStatusCode.OK })
    return result
  } catch (error) {
    span.setStatus({ code: SpanStatusCode.ERROR })
    span.recordException(error)
    throw error
  } finally {
    span.end()
  }
}
```

## Alerting Rules

```yaml
# Alert on high error rate
- alert: HighErrorRate
  expr: rate(http_errors_total[5m]) / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Error rate above 5%"

# Alert on latency
- alert: HighLatency
  expr: histogram_quantile(0.99, http_request_duration_seconds) > 2
  for: 5m
  labels:
    severity: warning
```

## Health Checks

```typescript
// app/api/health/route.ts
export async function GET() {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    external: await checkExternalAPIs()
  }

  const healthy = Object.values(checks).every(c => c.status === 'ok')

  return Response.json({
    status: healthy ? 'healthy' : 'unhealthy',
    checks,
    version: process.env.GIT_SHA
  }, { status: healthy ? 200 : 503 })
}
```

## Anti-Patterns

- Console.log in production
- No correlation IDs across services
- Alerting on symptoms, not causes
- No runbooks for alerts
- Metrics without dashboards

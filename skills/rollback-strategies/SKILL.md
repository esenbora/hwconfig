---
name: rollback-strategies
description: Use when planning deployments, handling production incidents, or setting up recovery procedures. Blue-green, canary, instant rollback. Triggers on: rollback, revert, deployment strategy, recovery, incident, blue-green, canary.
version: 1.0.0
---

# Rollback Strategies

> Every deployment should be reversible. Plan for failure before it happens.

---

## Quick Reference

```bash
# Vercel instant rollback
vercel rollback [deployment-url]

# Git revert
git revert HEAD --no-edit && git push

# Docker rollback
docker service update --rollback my-service

# Kubernetes rollback
kubectl rollout undo deployment/my-app
```

---

## Deployment Strategies

### 1. Blue-Green Deployment

Two identical environments, instant switch.

```
┌─────────────────────────────────────┐
│           Load Balancer              │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
   ┌─────────┐   ┌─────────┐
   │  Blue   │   │  Green  │
   │  (Live) │   │  (New)  │
   └─────────┘   └─────────┘
```

**Implementation:**

```typescript
// vercel.json for preview/production split
{
  "builds": [{ "src": "package.json", "use": "@vercel/next" }],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/$1",
      "headers": {
        "x-deployment-id": "$VERCEL_URL"
      }
    }
  ]
}
```

```yaml
# GitHub Actions blue-green
name: Blue-Green Deploy

jobs:
  deploy:
    steps:
      - name: Deploy to staging slot
        run: |
          vercel deploy --prod=false > deployment-url.txt

      - name: Run smoke tests
        run: |
          URL=$(cat deployment-url.txt)
          npm run test:e2e -- --baseUrl=$URL

      - name: Promote to production
        if: success()
        run: vercel promote $(cat deployment-url.txt)
```

### 2. Canary Deployment

Gradual traffic shift with monitoring.

```
Traffic Distribution:
├── 95% → Current Version
└── 5%  → Canary Version

If canary healthy after 30min:
├── 90% → Current Version
└── 10% → Canary Version

Continue until 100% or rollback
```

**Implementation:**

```typescript
// middleware.ts - Simple canary routing
import { NextResponse } from 'next/server'

export function middleware(request: NextRequest) {
  // Check if user is in canary group
  const userId = request.cookies.get('userId')?.value
  const canaryPercentage = parseInt(process.env.CANARY_PERCENTAGE || '0')

  if (userId && hashUser(userId) < canaryPercentage) {
    // Rewrite to canary deployment
    const canaryUrl = process.env.CANARY_URL
    return NextResponse.rewrite(new URL(request.pathname, canaryUrl))
  }

  return NextResponse.next()
}
```

### 3. Rolling Deployment

Gradual instance replacement.

```yaml
# Kubernetes rolling update
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra pods during update
      maxUnavailable: 0  # Always maintain capacity
```

---

## Instant Rollback Patterns

### Vercel Rollback

```bash
# List recent deployments
vercel ls

# Rollback to specific deployment
vercel rollback https://my-app-abc123.vercel.app

# Or via dashboard
# Project → Deployments → ... → Promote to Production
```

### Database Rollback

```typescript
// Migration with rollback support
// migrations/20240115_add_user_status.ts

export async function up(db: Database) {
  await db.schema.alterTable('users', (table) => {
    table.string('status').defaultTo('active')
  })
}

export async function down(db: Database) {
  await db.schema.alterTable('users', (table) => {
    table.dropColumn('status')
  })
}
```

```bash
# Rollback last migration
npx drizzle-kit down

# Or with Prisma
npx prisma migrate reset --skip-seed
```

### Feature Flag Rollback

```typescript
// Instant disable without deployment
await db.featureFlag.update({
  where: { name: 'new-checkout' },
  data: { enabled: false }
})

// Or via API
await fetch('/api/admin/flags', {
  method: 'PUT',
  body: JSON.stringify({ name: 'new-checkout', enabled: false })
})
```

---

## Incident Response Playbook

### Step 1: Detect

```typescript
// Automated alerting
const THRESHOLDS = {
  errorRate: 0.01,      // 1% errors
  p99Latency: 2000,     // 2 seconds
  successRate: 0.99,    // 99% success
}

async function monitorDeployment(deploymentId: string) {
  const metrics = await getMetrics(deploymentId, '5m')

  if (metrics.errorRate > THRESHOLDS.errorRate) {
    await triggerAlert('HIGH_ERROR_RATE', { deploymentId, ...metrics })
    return false
  }

  if (metrics.p99Latency > THRESHOLDS.p99Latency) {
    await triggerAlert('HIGH_LATENCY', { deploymentId, ...metrics })
    return false
  }

  return true
}
```

### Step 2: Assess

```markdown
## Incident Assessment Checklist

1. What's broken?
   - [ ] Frontend errors?
   - [ ] API failures?
   - [ ] Database issues?
   - [ ] Third-party service?

2. What changed?
   - [ ] Recent deployment?
   - [ ] Configuration change?
   - [ ] Traffic spike?
   - [ ] External dependency?

3. Impact scope?
   - [ ] All users?
   - [ ] Specific region?
   - [ ] Specific feature?
   - [ ] Specific user type?
```

### Step 3: Decide

```
Rollback Decision Matrix:

| Impact      | Confidence in Fix | Action           |
|-------------|-------------------|------------------|
| High        | Low               | ROLLBACK NOW     |
| High        | High              | Hotfix (15min)   |
| Medium      | Low               | ROLLBACK         |
| Medium      | High              | Hotfix (30min)   |
| Low         | Any               | Monitor + Fix    |
```

### Step 4: Execute

```bash
# Option A: Instant rollback (preferred)
vercel rollback [previous-deployment-url]

# Option B: Git revert + deploy
git revert HEAD --no-edit
git push origin main
# Wait for CI/CD

# Option C: Feature flag disable
curl -X PUT https://api.example.com/admin/flags \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "broken-feature", "enabled": false}'
```

### Step 5: Verify

```bash
# Check error rate dropping
curl https://api.example.com/metrics | jq '.errorRate'

# Run smoke tests
npm run test:smoke

# Check user reports
# Monitor #support channel
```

---

## Automated Rollback

### GitHub Actions with Rollback

```yaml
name: Deploy with Auto-Rollback

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Get previous deployment
        id: previous
        run: echo "url=$(vercel ls --prod -1 | tail -1)" >> $GITHUB_OUTPUT

      - name: Deploy
        id: deploy
        run: |
          URL=$(vercel deploy --prod)
          echo "url=$URL" >> $GITHUB_OUTPUT

      - name: Smoke test
        id: smoke
        continue-on-error: true
        run: |
          sleep 30  # Wait for deployment
          npm run test:smoke -- --baseUrl=${{ steps.deploy.outputs.url }}

      - name: Auto-rollback on failure
        if: steps.smoke.outcome == 'failure'
        run: |
          echo "Smoke tests failed, rolling back..."
          vercel rollback ${{ steps.previous.outputs.url }}

          # Notify team
          curl -X POST $SLACK_WEBHOOK \
            -d '{"text": "🚨 Auto-rollback triggered for deployment"}'
```

### Kubernetes Auto-Rollback

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  progressDeadlineSeconds: 600  # 10 min to complete
  strategy:
    type: RollingUpdate
  template:
    spec:
      containers:
        - name: app
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 3  # Rollback after 3 failures
```

---

## Rollback Checklist

```markdown
## Pre-Deployment Checklist
- [ ] Previous deployment URL saved
- [ ] Database migrations are reversible
- [ ] Feature flags for new features
- [ ] Monitoring alerts configured
- [ ] Rollback procedure documented

## During Deployment
- [ ] Monitor error rates
- [ ] Watch latency metrics
- [ ] Check for user complaints
- [ ] Verify core functionality

## Post-Incident
- [ ] Rollback successful?
- [ ] Services restored?
- [ ] Root cause identified?
- [ ] Incident documented?
- [ ] Prevention measures planned?
```

---

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Deploy without rollback plan | Always have previous URL saved |
| Irreversible database changes | Migrations with down() method |
| Big bang releases | Gradual rollout with flags |
| Manual rollback only | Automated rollback triggers |
| Skip smoke tests | Always verify after deploy |
| Ignore metrics during deploy | Active monitoring required |

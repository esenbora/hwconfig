---
name: background-jobs
description: Use when something takes too long, needs to run later, or needs scheduling. Queues, workers, cron jobs, async processing with Inngest, BullMQ, Trigger.dev. Triggers on: background job, queue, worker, cron, scheduled, async, long running, job queue, process later, inngest, bullmq, trigger.dev.
version: 1.0.0
---

# Background Jobs (2026)

> **Priority:** HIGH | **Auto-Load:** On queue, job, async processing work
> **Triggers:** background job, queue, worker, async, cron, scheduled, inngest, bullmq, trigger.dev

---

## Overview

Background jobs handle work that shouldn't block HTTP requests:
- Email sending
- Image/video processing
- AI/LLM operations
- Data sync/import
- Scheduled tasks (cron)
- Webhooks processing
- Long-running computations

---

## Solution Comparison

| Solution | Best For | Hosting | Complexity |
|----------|----------|---------|------------|
| **Inngest** | Serverless, event-driven | Managed | Low |
| **Trigger.dev** | Long-running, complex flows | Managed | Medium |
| **BullMQ** | High throughput, Redis-based | Self-hosted | Medium |
| **Quirrel** | Simple cron for Next.js | Managed/Self | Low |

### Decision Tree

```
Need background jobs?
├── Serverless environment (Vercel/Netlify)?
│   ├── Simple event-driven → Inngest
│   └── Long-running (>10min) → Trigger.dev
├── Self-hosted / VPS?
│   ├── High throughput → BullMQ
│   └── Simple cron → Quirrel or node-cron
└── Simple webhooks only → Upstash QStash
```

---

## Inngest (Serverless - Recommended)

Best for: Serverless deployments, event-driven workflows, step functions.

### Setup

```bash
npm install inngest
```

```typescript
// lib/inngest/client.ts
import { Inngest } from 'inngest'

export const inngest = new Inngest({
  id: 'my-app',
  schemas: new EventSchemas().fromRecord<Events>(),
})

// Define event types
type Events = {
  'user/signed.up': { data: { userId: string; email: string } }
  'email/send': { data: { to: string; subject: string; body: string } }
  'order/placed': { data: { orderId: string; userId: string } }
}
```

### Define Functions

```typescript
// lib/inngest/functions.ts
import { inngest } from './client'

// Simple function
export const sendWelcomeEmail = inngest.createFunction(
  { id: 'send-welcome-email' },
  { event: 'user/signed.up' },
  async ({ event, step }) => {
    // Step 1: Get user details
    const user = await step.run('get-user', async () => {
      return await db.user.findUnique({ where: { id: event.data.userId } })
    })

    // Step 2: Send email
    await step.run('send-email', async () => {
      await resend.emails.send({
        to: user.email,
        subject: 'Welcome!',
        html: welcomeTemplate(user),
      })
    })

    // Step 3: Update user
    await step.run('mark-welcomed', async () => {
      await db.user.update({
        where: { id: user.id },
        data: { welcomedAt: new Date() },
      })
    })

    return { success: true }
  }
)

// With retries and delays
export const processOrder = inngest.createFunction(
  {
    id: 'process-order',
    retries: 3,
    onFailure: async ({ error, event }) => {
      await alertSlack(`Order ${event.data.orderId} failed: ${error.message}`)
    },
  },
  { event: 'order/placed' },
  async ({ event, step }) => {
    // Wait for payment confirmation
    await step.sleep('wait-for-payment', '5m')

    // Check payment status
    const payment = await step.run('check-payment', async () => {
      return await stripe.paymentIntents.retrieve(event.data.paymentId)
    })

    if (payment.status !== 'succeeded') {
      throw new Error('Payment not confirmed')
    }

    // Continue with fulfillment...
  }
)
```

### Scheduled Jobs (Cron)

```typescript
// lib/inngest/functions.ts
export const dailyReport = inngest.createFunction(
  { id: 'daily-report' },
  { cron: '0 9 * * *' }, // Every day at 9 AM
  async ({ step }) => {
    const stats = await step.run('gather-stats', async () => {
      return await db.$queryRaw`
        SELECT
          COUNT(*) as total_users,
          COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') as new_users
        FROM users
      `
    })

    await step.run('send-report', async () => {
      await sendSlackMessage('#reports', formatDailyReport(stats))
    })
  }
)

// Weekly cleanup
export const weeklyCleanup = inngest.createFunction(
  { id: 'weekly-cleanup' },
  { cron: '0 3 * * 0' }, // Sunday at 3 AM
  async ({ step }) => {
    await step.run('cleanup-sessions', async () => {
      await db.session.deleteMany({
        where: { expiresAt: { lt: new Date() } },
      })
    })

    await step.run('cleanup-temp-files', async () => {
      await cleanupTempFiles()
    })
  }
)
```

### API Route Handler

```typescript
// app/api/inngest/route.ts
import { serve } from 'inngest/next'
import { inngest } from '@/lib/inngest/client'
import { sendWelcomeEmail, processOrder, dailyReport } from '@/lib/inngest/functions'

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    sendWelcomeEmail,
    processOrder,
    dailyReport,
  ],
})
```

### Triggering Events

```typescript
// In server actions or API routes
import { inngest } from '@/lib/inngest/client'

// Send event
await inngest.send({
  name: 'user/signed.up',
  data: { userId: user.id, email: user.email },
})

// Send multiple events
await inngest.send([
  { name: 'order/placed', data: { orderId: '123' } },
  { name: 'email/send', data: { to: email, subject: 'Confirmation' } },
])
```

---

## Trigger.dev (Long-Running Jobs)

Best for: Jobs >10 min, complex workflows, retries with backoff.

### Setup

```bash
npx trigger.dev@latest init
```

```typescript
// trigger.config.ts
import { defineConfig } from '@trigger.dev/sdk/v3'

export default defineConfig({
  project: 'proj_xxx',
  runtime: 'node',
  logLevel: 'log',
  retries: {
    enabledInDev: true,
    default: {
      maxAttempts: 3,
      minTimeoutInMs: 1000,
      maxTimeoutInMs: 10000,
      factor: 2,
    },
  },
})
```

### Define Tasks

```typescript
// trigger/tasks/process-video.ts
import { task, logger } from '@trigger.dev/sdk/v3'

export const processVideo = task({
  id: 'process-video',
  // Long timeout for video processing
  maxDuration: 300, // 5 minutes

  run: async (payload: { videoId: string; userId: string }) => {
    logger.info('Starting video processing', { videoId: payload.videoId })

    // Step 1: Download
    const video = await downloadVideo(payload.videoId)
    logger.info('Downloaded video', { size: video.size })

    // Step 2: Process (long operation)
    const processed = await transcodeVideo(video)
    logger.info('Transcoded video')

    // Step 3: Upload to storage
    const url = await uploadToS3(processed)
    logger.info('Uploaded to S3', { url })

    // Step 4: Update database
    await db.video.update({
      where: { id: payload.videoId },
      data: { processedUrl: url, status: 'completed' },
    })

    return { success: true, url }
  },
})
```

### Scheduled Tasks

```typescript
// trigger/tasks/scheduled.ts
import { schedules } from '@trigger.dev/sdk/v3'

export const dailyDigest = schedules.task({
  id: 'daily-digest',
  cron: '0 8 * * *', // 8 AM daily

  run: async () => {
    const users = await db.user.findMany({
      where: { dailyDigestEnabled: true },
    })

    for (const user of users) {
      await sendDigestEmail(user)
    }

    return { sent: users.length }
  },
})
```

### Triggering Tasks

```typescript
// In your app
import { tasks } from '@trigger.dev/sdk/v3'
import type { processVideo } from '@/trigger/tasks/process-video'

// Trigger async (returns immediately)
const handle = await tasks.trigger<typeof processVideo>('process-video', {
  videoId: '123',
  userId: 'user_456',
})

// Get result later
const result = await tasks.retrieve(handle)

// Trigger and wait (with timeout)
const result = await tasks.triggerAndWait<typeof processVideo>('process-video', {
  videoId: '123',
  userId: 'user_456',
}, { timeout: '10m' })
```

---

## BullMQ (Self-Hosted Redis)

Best for: High throughput, complete control, Redis infrastructure.

### Setup

```bash
npm install bullmq
```

```typescript
// lib/queue/connection.ts
import { Queue, Worker, QueueEvents } from 'bullmq'
import Redis from 'ioredis'

const connection = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: null,
})

export { connection }
```

### Define Queues

```typescript
// lib/queue/queues.ts
import { Queue } from 'bullmq'
import { connection } from './connection'

// Email queue
export const emailQueue = new Queue('email', {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: 100,
    removeOnFail: 500,
  },
})

// Heavy processing queue
export const processingQueue = new Queue('processing', {
  connection,
  defaultJobOptions: {
    attempts: 2,
    timeout: 300000, // 5 min
  },
})
```

### Define Workers

```typescript
// lib/queue/workers/email.worker.ts
import { Worker, Job } from 'bullmq'
import { connection } from '../connection'

interface EmailJobData {
  to: string
  subject: string
  template: string
  data: Record<string, any>
}

const emailWorker = new Worker<EmailJobData>(
  'email',
  async (job: Job<EmailJobData>) => {
    const { to, subject, template, data } = job.data

    await job.updateProgress(10)

    // Render template
    const html = await renderTemplate(template, data)
    await job.updateProgress(50)

    // Send email
    const result = await resend.emails.send({
      to,
      subject,
      html,
    })
    await job.updateProgress(100)

    return { messageId: result.id }
  },
  {
    connection,
    concurrency: 5, // Process 5 jobs at once
    limiter: {
      max: 100,
      duration: 1000, // Max 100 jobs per second
    },
  }
)

emailWorker.on('completed', (job) => {
  console.log(`Email job ${job.id} completed`)
})

emailWorker.on('failed', (job, error) => {
  console.error(`Email job ${job?.id} failed:`, error)
})

export { emailWorker }
```

### Adding Jobs

```typescript
// In your app
import { emailQueue, processingQueue } from '@/lib/queue/queues'

// Add single job
await emailQueue.add('send-welcome', {
  to: 'user@example.com',
  subject: 'Welcome!',
  template: 'welcome',
  data: { name: 'John' },
})

// Add with options
await emailQueue.add(
  'send-notification',
  { to: 'user@example.com', subject: 'Alert' },
  {
    delay: 5000, // Wait 5 seconds
    priority: 1, // Higher priority
    jobId: `notification-${userId}`, // Prevent duplicates
  }
)

// Add bulk jobs
await emailQueue.addBulk([
  { name: 'send-digest', data: { userId: '1' } },
  { name: 'send-digest', data: { userId: '2' } },
  { name: 'send-digest', data: { userId: '3' } },
])

// Scheduled/recurring jobs
await emailQueue.add(
  'daily-report',
  { type: 'daily' },
  {
    repeat: {
      pattern: '0 9 * * *', // Every day at 9 AM
    },
  }
)
```

### API Route for Webhook Processing

```typescript
// app/api/webhook/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { processingQueue } from '@/lib/queue/queues'

export async function POST(request: NextRequest) {
  const body = await request.text()
  const signature = request.headers.get('stripe-signature')!

  // Verify webhook
  const event = stripe.webhooks.constructEvent(body, signature, secret)

  // Queue for background processing
  await processingQueue.add('stripe-webhook', {
    eventId: event.id,
    type: event.type,
    data: event.data,
  })

  // Return immediately
  return NextResponse.json({ received: true })
}
```

---

## Upstash QStash (Simple Webhooks)

Best for: Simple async HTTP calls, Vercel/serverless, no infrastructure.

### Setup

```bash
npm install @upstash/qstash
```

```typescript
// lib/qstash.ts
import { Client } from '@upstash/qstash'

export const qstash = new Client({
  token: process.env.QSTASH_TOKEN!,
})
```

### Publish Messages

```typescript
// In your app
import { qstash } from '@/lib/qstash'

// Send to your own endpoint
await qstash.publishJSON({
  url: 'https://yourapp.com/api/process',
  body: { userId: '123', action: 'send-email' },
})

// With delay
await qstash.publishJSON({
  url: 'https://yourapp.com/api/reminder',
  body: { userId: '123' },
  delay: 60 * 60, // 1 hour delay
})

// Scheduled
await qstash.publishJSON({
  url: 'https://yourapp.com/api/daily-task',
  body: { type: 'cleanup' },
  cron: '0 3 * * *', // Every day at 3 AM
})
```

### Receiver Endpoint

```typescript
// app/api/process/route.ts
import { Receiver } from '@upstash/qstash'
import { NextRequest, NextResponse } from 'next/server'

const receiver = new Receiver({
  currentSigningKey: process.env.QSTASH_CURRENT_SIGNING_KEY!,
  nextSigningKey: process.env.QSTASH_NEXT_SIGNING_KEY!,
})

export async function POST(request: NextRequest) {
  const body = await request.text()
  const signature = request.headers.get('upstash-signature')!

  // Verify signature
  const isValid = await receiver.verify({
    body,
    signature,
    url: request.url,
  })

  if (!isValid) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 })
  }

  const data = JSON.parse(body)

  // Process the job
  await processJob(data)

  return NextResponse.json({ success: true })
}
```

---

## Patterns

### Idempotency

```typescript
// Always make jobs idempotent
export const processPayment = inngest.createFunction(
  { id: 'process-payment' },
  { event: 'payment/requested' },
  async ({ event, step }) => {
    // Check if already processed
    const existing = await step.run('check-existing', async () => {
      return await db.payment.findUnique({
        where: { idempotencyKey: event.data.idempotencyKey },
      })
    })

    if (existing) {
      return { status: 'already-processed', paymentId: existing.id }
    }

    // Process payment...
  }
)
```

### Fan-Out Pattern

```typescript
// Process many items in parallel
export const sendBulkEmails = inngest.createFunction(
  { id: 'send-bulk-emails' },
  { event: 'email/bulk.requested' },
  async ({ event, step }) => {
    const users = event.data.userIds

    // Fan out to individual sends
    await step.sendEvent(
      'fan-out-emails',
      users.map(userId => ({
        name: 'email/send',
        data: { userId, template: event.data.template },
      }))
    )
  }
)
```

### Dead Letter Queue

```typescript
// BullMQ dead letter queue
const mainQueue = new Queue('main', { connection })
const dlq = new Queue('dead-letter', { connection })

const worker = new Worker(
  'main',
  async (job) => {
    // Process job
  },
  {
    connection,
    settings: {
      backoffStrategy: (attemptsMade) => {
        return Math.min(1000 * Math.pow(2, attemptsMade), 30000)
      },
    },
  }
)

worker.on('failed', async (job, error) => {
  if (job && job.attemptsMade >= job.opts.attempts!) {
    // Move to DLQ after all retries exhausted
    await dlq.add('failed-job', {
      originalJob: job.data,
      error: error.message,
      failedAt: new Date(),
    })
  }
})
```

---

## Best Practices

### Do
```
✅ Make all jobs idempotent
✅ Use unique job IDs for deduplication
✅ Set appropriate timeouts
✅ Implement retries with exponential backoff
✅ Log job progress and completion
✅ Monitor queue depths and processing times
✅ Use dead letter queues for failed jobs
```

### Don't
```
❌ Store large payloads in job data (use references)
❌ Rely on job ordering (use priorities instead)
❌ Process jobs synchronously in API routes
❌ Forget to handle worker shutdown gracefully
❌ Skip idempotency for financial operations
```

---

## Checklist

```markdown
Setup:
[ ] Queue system chosen based on requirements
[ ] Connection/client configured
[ ] Workers/handlers defined

Reliability:
[ ] Jobs are idempotent
[ ] Retries configured with backoff
[ ] Dead letter queue for failures
[ ] Timeouts set appropriately

Monitoring:
[ ] Job completion logged
[ ] Failed jobs alerting
[ ] Queue depth monitoring
[ ] Processing time metrics

Operations:
[ ] Graceful shutdown handling
[ ] Job data is serializable
[ ] Large payloads stored externally
```

---

## Related Skills

- `redis` - Redis for BullMQ
- `server-actions` - Triggering jobs from actions
- `rate-limiting` - Rate limit job processing

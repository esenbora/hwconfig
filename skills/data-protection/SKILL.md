---
name: data-protection
description: Use when handling sensitive data, encryption, or secrets. Data protection patterns. Triggers on: data protection, encrypt, encryption, secrets, sensitive data, pii, gdpr, privacy.
version: 1.0.0
detect: ["security-audit"]
---

# Data Protection & Secrets Management

Comprehensive data protection and secrets handling patterns.

## Secrets Management

### Critical: Never Hardcode Secrets

```typescript
// ❌ CRITICAL: Hardcoded secrets
const STRIPE_KEY = "sk_live_abc123xyz"
const DB_PASSWORD = "super_secret_password"
const JWT_SECRET = "my-jwt-secret"

// ❌ CRITICAL: Secrets in client-side code
// This file will be bundled and exposed!
const API_KEY = process.env.STRIPE_SECRET_KEY // In client component

// ✅ SECURE: Environment variables
const STRIPE_KEY = process.env.STRIPE_SECRET_KEY

// ✅ SECURE: Server-only secrets
// In Server Component or API route only
import 'server-only'
const secret = process.env.SECRET_KEY
```

### Environment Variable Security

```typescript
// ✅ Validate required env vars at startup
const requiredEnvVars = [
  'DATABASE_URL',
  'STRIPE_SECRET_KEY',
  'CLERK_SECRET_KEY',
] as const

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`)
  }
}

// ✅ Type-safe env access
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  NODE_ENV: z.enum(['development', 'production', 'test']),
})

export const env = envSchema.parse(process.env)
```

### .gitignore Requirements

```gitignore
# ✅ Always ignore these
.env
.env.local
.env.*.local
.env.production
*.pem
*.key
credentials.json
serviceAccountKey.json
```

## Encryption

### Data at Rest

```typescript
import crypto from 'crypto'

const ALGORITHM = 'aes-256-gcm'
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex') // 32 bytes

// ✅ Encrypt sensitive data before storage
export function encrypt(text: string): string {
  const iv = crypto.randomBytes(16)
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv)
  
  let encrypted = cipher.update(text, 'utf8', 'hex')
  encrypted += cipher.final('hex')
  
  const authTag = cipher.getAuthTag()
  
  // Return iv:authTag:encrypted
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`
}

export function decrypt(encryptedText: string): string {
  const [ivHex, authTagHex, encrypted] = encryptedText.split(':')
  
  const iv = Buffer.from(ivHex, 'hex')
  const authTag = Buffer.from(authTagHex, 'hex')
  
  const decipher = crypto.createDecipheriv(ALGORITHM, KEY, iv)
  decipher.setAuthTag(authTag)
  
  let decrypted = decipher.update(encrypted, 'hex', 'utf8')
  decrypted += decipher.final('utf8')
  
  return decrypted
}

// Usage
const encryptedSSN = encrypt(user.ssn)
await db.user.create({
  data: {
    ...user,
    ssn: encryptedSSN
  }
})
```

### Data in Transit

```typescript
// ✅ Force HTTPS
// next.config.ts
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          }
        ]
      }
    ]
  }
}

// ✅ Secure cookie flags
cookies().set('session', token, {
  secure: true, // HTTPS only
  httpOnly: true,
  sameSite: 'strict'
})
```

## Sensitive Data in Logs

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Logging passwords
console.log('Login attempt:', { email, password })

// ❌ CRITICAL: Logging tokens
console.log('User session:', session) // Contains token!

// ❌ HIGH: Logging PII
console.log('User data:', user) // SSN, credit card, etc.

// ❌ HIGH: Logging in error messages
throw new Error(`DB error for user ${user.email}: ${error}`)
```

### Secure Patterns

```typescript
// ✅ SECURE: Redact sensitive fields
function sanitizeForLog(obj: Record<string, any>): Record<string, any> {
  const sensitiveFields = [
    'password', 'token', 'secret', 'key', 'ssn', 
    'creditCard', 'cvv', 'authorization'
  ]
  
  const sanitized = { ...obj }
  
  for (const field of sensitiveFields) {
    if (field in sanitized) {
      sanitized[field] = '[REDACTED]'
    }
  }
  
  return sanitized
}

console.log('Login attempt:', sanitizeForLog({ email, password }))
// Output: { email: 'user@example.com', password: '[REDACTED]' }

// ✅ SECURE: Structured logging with automatic redaction
import pino from 'pino'

const logger = pino({
  redact: {
    paths: ['password', 'token', '*.password', '*.token', 'req.headers.authorization'],
    censor: '[REDACTED]'
  }
})

logger.info({ user: { email, password } }, 'Login attempt')
```

## PII Handling

### Data Classification

```typescript
// ✅ Classify data sensitivity
enum DataSensitivity {
  PUBLIC = 'public',        // Can be shown anywhere
  INTERNAL = 'internal',    // Internal use only
  CONFIDENTIAL = 'confidential', // Encrypted, need-to-know
  RESTRICTED = 'restricted' // Highest protection, audit logged
}

interface UserData {
  // PUBLIC
  id: string
  username: string
  
  // INTERNAL
  email: string
  createdAt: Date
  
  // CONFIDENTIAL
  phoneNumber: string  // Encrypt at rest
  dateOfBirth: Date    // Encrypt at rest
  
  // RESTRICTED
  ssn: string          // Encrypt, audit access
  taxId: string        // Encrypt, audit access
}
```

### Access Auditing

```typescript
// ✅ Audit access to sensitive data
async function getSensitiveUserData(
  requesterId: string, 
  targetUserId: string,
  reason: string
) {
  // Log access attempt
  await db.auditLog.create({
    data: {
      action: 'ACCESS_SENSITIVE_DATA',
      requesterId,
      targetUserId,
      reason,
      timestamp: new Date(),
      ipAddress: getClientIP(),
    }
  })
  
  // Check authorization
  const requester = await db.user.findUnique({ where: { id: requesterId } })
  if (!canAccessSensitiveData(requester, targetUserId)) {
    throw new Error('Unauthorized access to sensitive data')
  }
  
  // Return decrypted data
  const user = await db.user.findUnique({ where: { id: targetUserId } })
  return {
    ...user,
    ssn: decrypt(user.ssn)
  }
}
```

## Database Security

### Row Level Security (RLS)

```sql
-- ✅ Enable RLS for multi-tenant data
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can only see their own documents
CREATE POLICY user_documents ON documents
  FOR ALL
  USING (user_id = current_setting('app.current_user_id')::uuid);

-- Org members can see org documents
CREATE POLICY org_documents ON documents
  FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = current_setting('app.current_user_id')::uuid
    )
  );
```

### Connection Security

```typescript
// ✅ Secure database connection
const connectionString = new URL(process.env.DATABASE_URL!)

// Ensure SSL is required in production
if (process.env.NODE_ENV === 'production') {
  connectionString.searchParams.set('sslmode', 'require')
}

// ✅ Prisma with SSL
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // For production, ensure SSL: ?sslmode=require
}
```

## Third-Party Integration Security

```typescript
// ✅ Validate webhook signatures
export async function POST(req: Request) {
  const signature = req.headers.get('stripe-signature')!
  const body = await req.text()
  
  let event
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (err) {
    console.error('Webhook signature verification failed')
    return new Response('Invalid signature', { status: 400 })
  }
  
  // Process verified webhook
}

// ✅ Validate OAuth state parameter
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const state = searchParams.get('state')
  const storedState = cookies().get('oauth_state')?.value
  
  if (!state || state !== storedState) {
    return new Response('Invalid state parameter', { status: 400 })
  }
  
  // Continue OAuth flow
}
```

## Audit Checklist

```markdown
## Data Protection Audit

### Critical
- [ ] No hardcoded secrets in code
- [ ] .env files in .gitignore
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced (HSTS header)

### High
- [ ] No PII in logs
- [ ] Webhook signatures validated
- [ ] Database connections use SSL
- [ ] Access to sensitive data audited

### Medium
- [ ] Environment variables typed and validated
- [ ] Data classified by sensitivity
- [ ] Encryption keys properly managed
- [ ] Regular secret rotation process

### Low
- [ ] Data retention policies implemented
- [ ] GDPR/CCPA compliance measures
- [ ] Data export/deletion capabilities
```

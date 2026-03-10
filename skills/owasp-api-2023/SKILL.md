---
name: owasp-api-2023
description: Use for API security best practices. OWASP API Security Top 10. Triggers on: owasp, api security, security best practices.
version: 1.0.0
---

# OWASP API Security Top 10 (2023)

> **Priority:** CRITICAL | **Auto-Load:** On API/endpoint work
> **Triggers:** api security, owasp, authorization, authentication, endpoint, api route

---

## Overview

The OWASP API Security Top 10 2023 represents the most critical security risks to APIs. Every API endpoint should be checked against these vulnerabilities.

---

## API1:2023 - Broken Object Level Authorization (BOLA)

**Risk:** Attacker accesses other users' data by manipulating object IDs

### Vulnerable Code

```typescript
// VULNERABLE - No ownership check
app.get('/api/users/:id', async (req, res) => {
  const user = await db.users.findById(req.params.id);
  return res.json(user);  // Anyone can access any user!
});
```

### Secure Code

```typescript
// SECURE - Validates ownership
app.get('/api/users/:id', async (req, res) => {
  const user = await db.users.findById(req.params.id);

  // Verify ownership or admin status
  if (user.id !== req.user.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  return res.json(user);
});

// Next.js API Route pattern
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const session = await getServerSession();
  if (!session) return new Response('Unauthorized', { status: 401 });

  const resource = await db.resource.findUnique({
    where: { id: params.id },
  });

  // ALWAYS check ownership
  if (resource.userId !== session.user.id) {
    return new Response('Forbidden', { status: 403 });
  }

  return Response.json(resource);
}
```

### Checklist

- [ ] Every endpoint validates resource ownership
- [ ] Use UUIDs instead of sequential IDs (harder to guess)
- [ ] Implement access control checks at data layer
- [ ] Log authorization failures for monitoring

---

## API2:2023 - Broken Authentication

**Risk:** Weak authentication allows attackers to assume other identities

### Requirements

```typescript
// Rate limiting on auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 5,                     // 5 attempts
  message: 'Too many login attempts',
  keyGenerator: (req) => req.ip,
});

app.post('/api/auth/login', authLimiter, loginHandler);

// Password hashing (bcrypt with 12+ rounds)
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;  // Minimum 12 for security

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

// Generic error message (don't reveal if user exists)
// BAD
if (!user) return res.status(401).json({ error: 'User not found' });
if (!validPassword) return res.status(401).json({ error: 'Wrong password' });

// GOOD
return res.status(401).json({ error: 'Invalid credentials' });
```

### MFA Implementation

```typescript
import { authenticator } from 'otplib';

// Generate TOTP secret
const secret = authenticator.generateSecret();

// Verify TOTP code
const isValid = authenticator.verify({
  token: userProvidedCode,
  secret: user.totpSecret,
});

// Require MFA for sensitive operations
async function sensitiveOperation(req, res) {
  if (!req.session.mfaVerified) {
    return res.status(403).json({
      error: 'MFA required',
      requiresMfa: true
    });
  }
  // Proceed with operation
}
```

### Checklist

- [ ] Rate limiting on auth endpoints (5 attempts / 15 min)
- [ ] bcrypt with 12+ salt rounds
- [ ] Generic error messages
- [ ] MFA available for sensitive operations
- [ ] Secure session management
- [ ] Password complexity requirements enforced

---

## API3:2023 - Broken Object Property Level Authorization

**Risk:** Mass assignment allows modifying protected fields

### Vulnerable Code

```typescript
// VULNERABLE - Direct object spread
app.put('/api/users/:id', async (req, res) => {
  const user = await db.users.update(req.params.id, req.body);
  // Attacker can set: { isAdmin: true, role: "admin", balance: 9999999 }
  return res.json(user);
});
```

### Secure Code

```typescript
// SECURE - Explicit allowlist
app.put('/api/users/:id', async (req, res) => {
  const { name, email, avatar } = req.body;  // Only allowed fields

  const user = await db.users.update(req.params.id, {
    name,
    email,
    avatar,
    // isAdmin, role, balance CANNOT be set by user
  });

  return res.json(user);
});

// Using Zod for validation
import { z } from 'zod';

const updateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
  avatar: z.string().url().optional(),
});

app.put('/api/users/:id', async (req, res) => {
  const data = updateUserSchema.parse(req.body);
  const user = await db.users.update(req.params.id, data);
  return res.json(user);
});
```

### Response Filtering

```typescript
// SECURE - Don't expose sensitive fields in responses
const userResponse = {
  id: user.id,
  name: user.name,
  email: user.email,
  // NEVER expose: passwordHash, totpSecret, internalNotes, etc.
};
```

### Checklist

- [ ] Explicit allowlist for updatable fields
- [ ] Schema validation (Zod) for all inputs
- [ ] Filter sensitive fields from responses
- [ ] Different schemas for create vs update

---

## API4:2023 - Unrestricted Resource Consumption

**Risk:** No limits on resource usage enables DoS and cost attacks

### Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                   // 100 requests per window
  keyGenerator: (req) => req.user?.id || req.ip,
  standardHeaders: true,
  legacyHeaders: false,
});

// Expensive operation rate limit
const expensiveLimiter = rateLimit({
  windowMs: 60 * 1000,  // 1 minute
  max: 5,               // 5 requests per minute
  message: 'Too many requests for this resource',
});

app.use('/api', apiLimiter);
app.post('/api/ai/generate', expensiveLimiter, generateHandler);
```

### Request Size Limits

```typescript
import express from 'express';

// Limit JSON body size
app.use(express.json({ limit: '100kb' }));

// Limit file uploads
import multer from 'multer';
const upload = multer({
  limits: {
    fileSize: 10 * 1024 * 1024,  // 10MB max
    files: 5,                     // Max 5 files
  },
});
```

### Pagination

```typescript
// Enforce pagination limits
app.get('/api/items', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);  // Max 100

  const items = await db.items.findMany({
    skip: (page - 1) * limit,
    take: limit,
  });

  return res.json({
    items,
    page,
    limit,
    hasMore: items.length === limit,
  });
});
```

### Checklist

- [ ] Rate limiting on all endpoints
- [ ] Stricter limits on expensive operations
- [ ] Request body size limits
- [ ] File upload size and count limits
- [ ] Pagination enforced with max limits
- [ ] Timeouts on long-running operations

---

## API5:2023 - Broken Function Level Authorization

**Risk:** Users access admin/privileged functions

### Permission Checking

```typescript
// Permission middleware
function requirePermission(permission: string) {
  return async (req, res, next) => {
    const user = req.user;

    if (!user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!user.permissions.includes(permission)) {
      return res.status(403).json({
        error: `Missing permission: ${permission}`
      });
    }

    next();
  };
}

// Usage
app.delete('/api/users/:id',
  requirePermission('users:delete'),
  deleteUserHandler
);

app.get('/api/admin/stats',
  requirePermission('admin:read'),
  adminStatsHandler
);
```

### Role-Based Access Control

```typescript
const rolePermissions = {
  user: ['users:read:own', 'posts:create', 'posts:read'],
  moderator: ['users:read:own', 'posts:*', 'comments:delete'],
  admin: ['*'],
};

function hasPermission(user: User, required: string): boolean {
  const permissions = rolePermissions[user.role] || [];

  return permissions.some(p => {
    if (p === '*') return true;
    if (p === required) return true;
    if (p.endsWith(':*')) {
      const prefix = p.slice(0, -1);
      return required.startsWith(prefix);
    }
    return false;
  });
}
```

### Checklist

- [ ] Every endpoint checks permissions
- [ ] Admin functions separated and protected
- [ ] Role-based access control implemented
- [ ] Permissions logged for auditing
- [ ] No permission checks in client code only

---

## API6:2023 - Unrestricted Access to Sensitive Business Flows

**Risk:** Automated abuse of business logic (scraping, bots, spam)

### Anti-Automation Measures

```typescript
// CAPTCHA for high-value actions
app.post('/api/signup', async (req, res) => {
  const { captchaToken } = req.body;

  const captchaValid = await verifyCaptcha(captchaToken);
  if (!captchaValid) {
    return res.status(400).json({ error: 'Invalid CAPTCHA' });
  }

  // Proceed with signup
});

// Honeypot field
app.post('/api/contact', async (req, res) => {
  // Hidden field that should be empty
  if (req.body.website) {  // Bots fill this
    return res.status(400).json({ error: 'Invalid submission' });
  }

  // Proceed with submission
});

// Device fingerprinting
app.post('/api/purchase', async (req, res) => {
  const fingerprint = req.headers['x-device-fingerprint'];

  const purchaseCount = await db.purchases.count({
    where: {
      fingerprint,
      createdAt: { gte: new Date(Date.now() - 86400000) }  // Last 24h
    }
  });

  if (purchaseCount > 10) {
    return res.status(429).json({ error: 'Purchase limit exceeded' });
  }
});
```

### Checklist

- [ ] CAPTCHA on signup, contact, purchase flows
- [ ] Honeypot fields on forms
- [ ] Device fingerprinting for abuse detection
- [ ] Behavioral analysis for bot detection
- [ ] Business logic rate limits

---

## API7:2023 - Server-Side Request Forgery (SSRF)

**Risk:** Attacker makes server fetch malicious or internal URLs

### Vulnerable Code

```typescript
// VULNERABLE - Fetches any URL
app.post('/api/fetch-url', async (req, res) => {
  const response = await fetch(req.body.url);
  return res.json(await response.json());
});
```

### Secure Code

```typescript
import { URL } from 'url';
import dns from 'dns/promises';

const ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com'];

const PRIVATE_IP_RANGES = [
  /^127\./,                // Loopback
  /^10\./,                 // Private A
  /^172\.(1[6-9]|2\d|3[01])\./,  // Private B
  /^192\.168\./,           // Private C
  /^169\.254\./,           // Link-local
  /^0\./,                  // Current network
];

function isPrivateIP(ip: string): boolean {
  return PRIVATE_IP_RANGES.some(range => range.test(ip));
}

app.post('/api/fetch-url', async (req, res) => {
  try {
    const url = new URL(req.body.url);

    // Whitelist check
    if (!ALLOWED_HOSTS.includes(url.hostname)) {
      return res.status(400).json({ error: 'Host not allowed' });
    }

    // Protocol check
    if (!['http:', 'https:'].includes(url.protocol)) {
      return res.status(400).json({ error: 'Invalid protocol' });
    }

    // Resolve hostname and check for private IPs
    const addresses = await dns.resolve4(url.hostname);
    if (addresses.some(isPrivateIP)) {
      return res.status(400).json({ error: 'Private IP not allowed' });
    }

    const response = await fetch(url.toString(), {
      redirect: 'error',  // Don't follow redirects
      timeout: 5000,
    });

    return res.json(await response.json());
  } catch (error) {
    return res.status(400).json({ error: 'Invalid URL' });
  }
});
```

### Checklist

- [ ] Whitelist allowed hosts
- [ ] Block private IP ranges
- [ ] Validate URL protocol (http/https only)
- [ ] Don't follow redirects
- [ ] Set request timeouts
- [ ] DNS resolution validation

---

## API8:2023 - Security Misconfiguration

**Risk:** Insecure defaults, verbose errors, missing security headers

### Security Headers

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));

// Disable server identification
app.disable('x-powered-by');
```

### Error Handling

```typescript
// Production error handler
app.use((err, req, res, next) => {
  // Log detailed error server-side
  console.error('Error:', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    user: req.user?.id,
  });

  // Return generic message to client
  res.status(500).json({
    error: 'An unexpected error occurred',
    // NEVER expose: err.message, err.stack, SQL queries, etc.
  });
});
```

### Checklist

- [ ] Security headers configured (Helmet)
- [ ] Debug mode disabled in production
- [ ] Server version hidden
- [ ] Verbose errors only in logs
- [ ] CORS properly configured
- [ ] Unnecessary HTTP methods disabled

---

## API9:2023 - Improper Inventory Management

**Risk:** Untracked API versions, endpoints, or documentation

### Version Management

```typescript
// Deprecation headers
app.use('/api/v1/*', (req, res, next) => {
  res.setHeader('Deprecation', 'true');
  res.setHeader('Sunset', 'Sat, 01 Jun 2025 00:00:00 GMT');
  res.setHeader('Link', '</api/v2>; rel="successor-version"');
  next();
});

// Version routing
const v1Router = require('./routes/v1');
const v2Router = require('./routes/v2');

app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);
```

### Checklist

- [ ] API version inventory maintained
- [ ] Deprecation headers on old versions
- [ ] Sunset dates communicated
- [ ] Documentation for all endpoints
- [ ] Unused endpoints removed

---

## API10:2023 - Unsafe Consumption of APIs

**Risk:** Trusting third-party API responses without validation

### External API Validation

```typescript
import { z } from 'zod';

// Define expected schema
const externalApiResponseSchema = z.object({
  data: z.object({
    id: z.string(),
    amount: z.number().positive(),
    currency: z.enum(['USD', 'EUR', 'GBP']),
  }),
  status: z.enum(['success', 'pending', 'failed']),
});

async function fetchExternalApi(endpoint: string) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  try {
    const response = await fetch(endpoint, {
      signal: controller.signal,
    });

    const data = await response.json();

    // VALIDATE the response
    return externalApiResponseSchema.parse(data);
  } finally {
    clearTimeout(timeout);
  }
}

// Circuit breaker for external APIs
import CircuitBreaker from 'opossum';

const breaker = new CircuitBreaker(fetchExternalApi, {
  timeout: 5000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000,
});

breaker.on('open', () => console.log('Circuit opened'));
breaker.on('halfOpen', () => console.log('Circuit half-open'));
breaker.on('close', () => console.log('Circuit closed'));
```

### Checklist

- [ ] Validate all external API responses (Zod)
- [ ] Set request timeouts
- [ ] Implement circuit breakers
- [ ] Log external API failures
- [ ] Don't expose external errors to clients

---

## Quick Reference Checklist

| # | Risk | Key Control |
|---|------|-------------|
| API1 | BOLA | Ownership check on every resource access |
| API2 | Broken Auth | Rate limiting, bcrypt 12+, MFA |
| API3 | Property Auth | Allowlist updateable fields |
| API4 | Resource Consumption | Rate limits, pagination, size limits |
| API5 | Function Auth | Permission checks on all endpoints |
| API6 | Business Flow Abuse | CAPTCHA, fingerprinting, honeypots |
| API7 | SSRF | Whitelist hosts, block private IPs |
| API8 | Misconfiguration | Security headers, hide errors |
| API9 | Inventory | Version tracking, deprecation |
| API10 | Unsafe Consumption | Validate external responses |

---

## Resources

- [OWASP API Security Top 10 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [API Security Best Practices](https://roadmap.sh/best-practices/api-security)

---
name: audit
description: Use for security audits, code review, vulnerability analysis, or checking code quality. Comprehensive codebase analysis. Triggers on: audit, security audit, vulnerability, code review, check code, analyze code, find bugs, security check, penetration test.
argument-hint: "<scope-or-directory>"
version: 1.0.0
context: fork
agent: security
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---


## ORCHESTRATION

```yaml
Skills:
  Always:
    - security-first          # Security mindset
    - production-mindset      # Production standards
    - defensive-coding        # Edge cases & validation
    - owasp-api-2023          # API Security Top 10 2023

  Load Based on Stack:
    - nextjs-deep            # If Next.js (App Router security)
    - react-native-deep      # If React Native (mobile security)
    - drizzle-2026           # If Drizzle ORM (query security)
    - nextauth-deep / clerk-deep  # If auth provider
    - supabase-deep          # If Supabase (RLS policies)
    - postgresql-2026        # If PostgreSQL (query security)
    - security-deep          # Always for deep audits

Agents:
  Lead: security            # Security specialist leads audit
  Consult:
    - backend              # API and server security
    - data                 # Database and data protection
    - frontend             # XSS, client-side security
    - devops               # Infrastructure security
    - architect            # Security architecture review

Knowledge:
  Read First:
    - DONT_DO.md           # Known security mistakes in this project
    - CRITICAL_NOTES.md    # Project security requirements
    - progress.txt         # Codebase patterns that may affect security
    - sharp-edges.yaml     # Known gotchas with severity levels

  Update After:
    - DONT_DO.md           # Add discovered vulnerabilities as anti-patterns
    - CRITICAL_NOTES.md    # Add security requirements discovered
    - progress.txt         # Log audit completion and findings summary
    - sharp-edges.yaml     # Add new security gotchas discovered
```

---

## PHASE 1: SCOPE DETERMINATION

### Audit Scopes

| Scope | Focus Area | Duration |
|-------|------------|----------|
| `full` | Complete security + bug analysis | Comprehensive |
| `auth` | Authentication, authorization, sessions | Targeted |
| `api` | API endpoints, validation, rate limiting | Targeted |
| `data` | Database, PII, encryption, data flow | Targeted |
| `deps` | Dependency vulnerabilities, supply chain | Quick |
| `compliance` | GDPR, SOC2, HIPAA, PCI-DSS | Regulatory |

**If scope not specified, determine from project:**
- New project → Full audit
- Auth changes → Auth audit
- API changes → API audit
- Database changes → Data audit
- Regular check → Deps audit
- Going to production → Full + Compliance

---

## PHASE 2: RECONNAISSANCE

### 2.1 Technology Stack Detection

**Detect and catalog:**

```markdown
### Stack Analysis
- [ ] Framework: ___________
- [ ] Runtime: ___________
- [ ] Database: ___________
- [ ] ORM: ___________
- [ ] Auth Provider: ___________
- [ ] Payment Provider: ___________
- [ ] File Storage: ___________
- [ ] Email Service: ___________
- [ ] Analytics: ___________
- [ ] Error Tracking: ___________
```

### 2.2 Attack Surface Mapping

**Map all entry points:**

```
┌──────────────────────────────────────────────────────────────┐
│                        ATTACK SURFACE                        │
├──────────────────────────────────────────────────────────────┤
│  PUBLIC ENDPOINTS       │  AUTHENTICATED ENDPOINTS           │
│  - /api/auth/*          │  - /api/user/*                     │
│  - /api/public/*        │  - /api/admin/* (role-gated)       │
│  - Webhooks             │  - Server actions                  │
│                         │  - GraphQL/tRPC mutations          │
├──────────────────────────────────────────────────────────────┤
│  DATA FLOWS             │  EXTERNAL INTEGRATIONS             │
│  - User input → DB      │  - Payment APIs                    │
│  - File uploads         │  - OAuth providers                 │
│  - Third-party data     │  - Webhooks (inbound)              │
└──────────────────────────────────────────────────────────────┘
```

### 2.3 Critical File Identification

**Prioritize these for review:**

```
HIGH PRIORITY:
├── middleware.ts          # Auth/route protection
├── app/api/**            # All API routes
├── lib/auth.*            # Auth logic
├── lib/db.*              # Database connections
├── .env*                 # Environment files
├── next.config.*         # Security headers
└── prisma/schema.prisma  # Data model + relations

MEDIUM PRIORITY:
├── app/**/actions.ts     # Server actions
├── lib/validations/*     # Input validation
├── components/forms/*    # User input handling
└── hooks/use*.ts         # Data fetching hooks
```

---

## PHASE 3: THE 12 VIBE-CODING SECURITY RULES

> **80%+ of AI-assisted apps have critical vulnerabilities. These rules are NON-NEGOTIABLE.**

### Rule 1: No Direct Database Access

```
VIOLATION PATTERN:
Frontend component → Supabase/Firebase → Database

SECURE PATTERN:
Frontend → API Route (with auth) → Database
```

**Search for violations:**
```bash
# Direct client DB access
grep -rn "createClient\|createBrowserClient" --include="*.tsx" --include="*.jsx"
grep -rn "supabase\." --include="*.tsx" | grep -v "lib/\|api/"
grep -rn "firebase\." --include="*.tsx" | grep -v "lib/\|api/"
```

### Rule 2: Gatekeep Every Endpoint

```typescript
// ❌ CRITICAL: No auth check
export async function POST(req: Request) {
  const data = await req.json()
  await db.post.create({ data })
}

// ✅ SECURE: Auth + authorization
export async function POST(req: Request) {
  const { userId } = await auth()
  if (!userId) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  // Also check: Can this user perform this action?
  const hasPermission = await checkPermission(userId, 'posts:create')
  if (!hasPermission) return Response.json({ error: 'Forbidden' }, { status: 403 })

  await db.post.create({ data: { ...data, userId } })
}
```

**Search for violations:**
```bash
# API routes without auth
grep -rL "auth()\|getAuth\|getServerSession\|currentUser" app/api/**/route.ts
```

### Rule 3: Withhold, Don't Hide

```typescript
// ❌ CRITICAL: Client decides access
const PremiumContent = () => {
  const { user } = useUser()
  if (!user.isPremium) return <UpgradePrompt />
  return <SecretContent /> // Still downloaded!
}

// ✅ SECURE: Server withholds
export async function getPremiumContent() {
  const user = await auth()
  if (!user?.isPremium) return { content: null, requiresUpgrade: true }
  return { content: await fetchPremiumContent(), requiresUpgrade: false }
}
```

### Rule 4: Secrets Stay on Server

```bash
# Find exposed secrets
grep -rn "NEXT_PUBLIC_.*KEY\|NEXT_PUBLIC_.*SECRET\|NEXT_PUBLIC_.*TOKEN" .
grep -rn "EXPO_PUBLIC_.*KEY\|EXPO_PUBLIC_.*SECRET" .

# These should NEVER exist:
# NEXT_PUBLIC_OPENAI_KEY
# NEXT_PUBLIC_STRIPE_SECRET
# NEXT_PUBLIC_DATABASE_URL
# EXPO_PUBLIC_API_SECRET
```

### Rule 5: .env ≠ Safe

```markdown
UNDERSTAND THIS:
- .env prevents git commit (if in .gitignore)
- NEXT_PUBLIC_* is bundled into client JavaScript
- Anyone can view client bundle in browser DevTools
- .env.local vs .env has NO security difference for NEXT_PUBLIC_
```

### Rule 6: Server-Side Calculations

```typescript
// ❌ CRITICAL: Client calculates price
const CartTotal = ({ items }) => {
  const total = items.reduce((sum, item) => sum + item.price * item.qty, 0)
  const discount = applyPromoCode(total, promoCode) // Exploitable!
  return <Pay amount={total - discount} />
}

// ✅ SECURE: Server calculates
export async function calculateCart(items: CartItem[], promoCode?: string) {
  // Server validates items, prices from database
  const validatedItems = await validateCartItems(items)
  const subtotal = calculateSubtotal(validatedItems)
  const discount = await validateAndApplyPromo(promoCode, subtotal)
  return { subtotal, discount, total: subtotal - discount }
}
```

### Rule 7: Sanitize All Inputs

```typescript
// ❌ CRITICAL: SQL Injection
await db.$queryRaw`SELECT * FROM users WHERE email = '${email}'`

// ❌ CRITICAL: XSS
<div dangerouslySetInnerHTML={{ __html: userBio }} />

// ❌ CRITICAL: Command Injection
exec(`convert ${userFilename} output.png`)

// ✅ SECURE alternatives
await db.user.findUnique({ where: { email } }) // Parameterized
<div>{DOMPurify.sanitize(userBio)}</div>       // Sanitized
exec(`convert ${sanitizeFilename(userFilename)} output.png`)
```

### Rule 8: Rate Limit Everything

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'), // 10 requests per 10 seconds
})

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? '127.0.0.1'
  const { success, remaining } = await ratelimit.limit(ip)

  if (!success) {
    return Response.json(
      { error: 'Too many requests' },
      { status: 429, headers: { 'X-RateLimit-Remaining': remaining.toString() } }
    )
  }
  // ... handle request
}
```

### Rule 9: No Sensitive Logging

```bash
# Find sensitive logging
grep -rn "console.log.*password\|console.log.*token\|console.log.*key" --include="*.ts" --include="*.tsx"
grep -rn "console.log.*user)" --include="*.ts"  # May include password hash
grep -rn "console.log.*req.body\|console.log.*request" --include="*.ts"
```

### Rule 10: Audit with Rival AI

```markdown
RECOMMENDATION:
- Code with Claude → Audit with Gemini/GPT
- Different models catch different vulnerabilities
- Cross-validate security findings
- Use specialized security tools (Snyk, SonarQube)
```

### Rule 11: Update Dependencies

```bash
# Check vulnerabilities
npm audit
npm audit --json > audit-report.json

# Check outdated
npm outdated

# Fix automatically where safe
npm audit fix

# For breaking changes
npm audit fix --force  # Review changes carefully!
```

### Rule 12: Safe Error Messages

```typescript
// ❌ CRITICAL: Leaks internals
return Response.json({
  error: `Database error: ${err.message}`,
  stack: err.stack
}, { status: 500 })

// ✅ SECURE: Vague to client, detailed in logs
console.error('Database error:', { error: err, userId, action: 'createPost' })
return Response.json({ error: 'Something went wrong' }, { status: 500 })
```

---

## PHASE 4: OWASP API SECURITY TOP 10 2023 (MANDATORY)

> **API-specific vulnerabilities are the #1 attack vector in modern apps.**

### API1:2023 – Broken Object Level Authorization (BOLA)

**The #1 API vulnerability. Every endpoint MUST validate resource ownership.**

```typescript
// ❌ CRITICAL: Trusts user-provided ID
app.get('/api/users/:id', (req) => db.users.findById(req.params.id));

// ✅ SECURE: Validates ownership
app.get('/api/users/:id', async (req) => {
  const user = await db.users.findById(req.params.id);
  if (user.id !== req.user.id && !req.user.isAdmin) {
    throw new ForbiddenError('Cannot access this resource');
  }
  return user;
});
```

**Search patterns:**
```bash
# Find potential BOLA vulnerabilities
grep -rn "params.id\|params.userId" --include="*.ts" | grep -v "userId.*auth\|ownership"
grep -rn "findUnique.*params\|findFirst.*params" --include="*.ts"
```

### API2:2023 – Broken Authentication

**Check for:**
- [ ] Rate limiting on login (5 attempts per 15 min)
- [ ] bcrypt with 12+ rounds (or Argon2)
- [ ] MFA available for sensitive operations
- [ ] Don't reveal if username OR password is wrong
- [ ] Session invalidation on password change

### API3:2023 – Broken Object Property Level Authorization

**Mass assignment prevention - ALWAYS allowlist fields:**

```typescript
// ❌ CRITICAL: Mass assignment vulnerability
const user = await db.users.update(req.params.id, req.body);

// ✅ SECURE: Explicit field allowlist
const { name, email } = req.body;
const user = await db.users.update(req.params.id, { name, email });
// NEVER include: isAdmin, role, permissions, etc.
```

**Search patterns:**
```bash
# Find mass assignment risks
grep -rn "req.body\)" --include="*.ts" | grep -v "const.*=.*req.body"
grep -rn "\.update.*data:.*input\|\.create.*data:.*input" --include="*.ts"
```

### API4:2023 – Unrestricted Resource Consumption

**Rate limiting on ALL endpoints:**

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '1 m'),
});

// Check on every request
const { success, remaining } = await ratelimit.limit(userId || ip);
if (!success) return res.status(429).json({ error: 'Too many requests' });
```

**Also check:**
- [ ] Request size limits (`express.json({ limit: '100kb' })`)
- [ ] Query pagination enforced (no unlimited results)
- [ ] File upload size limits

### API5:2023 – Broken Function Level Authorization (BFLA)

**Every endpoint must check function-level permissions:**

```typescript
// ❌ CRITICAL: No permission check
export async function deleteUser(userId: string) {
  await db.user.delete({ where: { id: userId } });
}

// ✅ SECURE: Permission check
export async function deleteUser(userId: string) {
  const currentUser = await auth();
  if (!currentUser.hasPermission('users:delete')) {
    throw new ForbiddenError('Missing permission: users:delete');
  }
  await db.user.delete({ where: { id: userId } });
}
```

### API6:2023 – Unrestricted Access to Sensitive Business Flows

**Anti-automation for sensitive operations:**
- [ ] CAPTCHA on high-value actions
- [ ] Device fingerprinting for suspicious activity
- [ ] Honeypot fields in forms
- [ ] Rate limiting by business operation (not just endpoint)

### API7:2023 – Server Side Request Forgery (SSRF)

**CRITICAL: Never fetch user-controlled URLs without validation:**

```typescript
// ❌ CRITICAL: SSRF vulnerability
const response = await fetch(req.body.url);

// ✅ SECURE: Whitelist + URL validation
const allowedHosts = ['api.example.com', 'cdn.example.com'];
const url = new URL(req.body.url);

// Block private IPs
const privateRanges = ['127.', '10.', '192.168.', '172.16.', '169.254.'];
if (privateRanges.some(r => url.hostname.startsWith(r))) {
  throw new Error('Private IP not allowed');
}

if (!allowedHosts.includes(url.hostname)) {
  throw new Error('Host not in allowlist');
}

const response = await fetch(url.toString());
```

**Search patterns:**
```bash
# Find SSRF vectors
grep -rn "fetch.*req\.\|axios.*req\.\|got.*req\." --include="*.ts"
grep -rn "url.*body\|url.*query\|url.*params" --include="*.ts"
```

### API8:2023 – Security Misconfiguration

**Check:**
- [ ] Debug mode disabled in production
- [ ] Unnecessary HTTP methods disabled
- [ ] Security headers configured (HSTS, CSP, X-Frame-Options)
- [ ] Server version not exposed
- [ ] Stack traces not returned to client
- [ ] CORS properly configured (no `*` on authenticated endpoints)

### API9:2023 – Improper Inventory Management

**Check:**
- [ ] API versioning strategy documented
- [ ] Old API versions deprecated with sunset headers
- [ ] API gateway for centralized control
- [ ] All endpoints documented in OpenAPI spec

### API10:2023 – Unsafe Consumption of APIs

**Validate all external API responses:**

```typescript
// ❌ Trusting external API response
const data = await externalApi.getUser(id);
user.credits = data.credits; // What if they return 999999?

// ✅ Validate external responses
import { z } from 'zod';

const ExternalUserSchema = z.object({
  credits: z.number().min(0).max(10000),
});

const data = await externalApi.getUser(id);
const validated = ExternalUserSchema.parse(data);
user.credits = validated.credits;
```

**Also:**
- [ ] Timeouts on external API calls
- [ ] Circuit breaker pattern for external services
- [ ] Error handling for external API failures

---

## PHASE 5: OWASP WEB TOP 10 2021

### A01:2021 – Broken Access Control

**Check for:**
- [ ] Forced browsing (accessing /admin without admin role)
- [ ] IDOR (accessing /api/users/123 when you're user 456)
- [ ] Missing function-level access control
- [ ] CORS misconfiguration
- [ ] JWT token manipulation
- [ ] Metadata manipulation (hidden fields, cookies)

**Search patterns:**
```bash
# Routes without middleware protection
grep -rL "withAuth\|requireAuth\|protected" app/api/**/route.ts

# Direct ID access without ownership check
grep -rn "params.id\|params.userId" --include="*.ts" | grep -v "userId.*auth"
```

### A02:2021 – Cryptographic Failures

**Check for:**
- [ ] Sensitive data transmitted in cleartext
- [ ] Weak encryption algorithms (MD5, SHA1 for passwords)
- [ ] Hardcoded encryption keys
- [ ] Missing TLS/HTTPS
- [ ] Insecure random number generation

**Search patterns:**
```bash
# Weak hashing
grep -rn "md5\|sha1" --include="*.ts" | grep -v node_modules
grep -rn "crypto.createHash" --include="*.ts"

# Hardcoded keys
grep -rn "secret.*=.*['\"]" --include="*.ts" | grep -v ".env"
```

### A03:2021 – Injection

**Check for:**
- [ ] SQL injection
- [ ] NoSQL injection
- [ ] Command injection
- [ ] LDAP injection
- [ ] Expression Language injection
- [ ] XSS (reflected, stored, DOM)

**Search patterns:**
```bash
# SQL injection vectors
grep -rn "queryRaw\|executeRaw" --include="*.ts"
grep -rn "\$\{.*\}" --include="*.ts" | grep -i "query\|sql"

# Command injection
grep -rn "exec(\|spawn(\|execSync" --include="*.ts"

# XSS vectors
grep -rn "dangerouslySetInnerHTML\|innerHTML" --include="*.tsx"
```

### A04:2021 – Insecure Design

**Check for:**
- [ ] Missing rate limiting
- [ ] No account lockout
- [ ] Weak password requirements
- [ ] Missing MFA option
- [ ] Insecure password recovery
- [ ] Trust boundary violations

### A05:2021 – Security Misconfiguration

**Check for:**
- [ ] Default credentials
- [ ] Unnecessary features enabled
- [ ] Missing security headers
- [ ] Verbose error messages
- [ ] Unpatched systems
- [ ] Insecure CORS

**Check security headers:**
```typescript
// next.config.js should have:
headers: [
  {
    source: '/:path*',
    headers: [
      { key: 'X-DNS-Prefetch-Control', value: 'on' },
      { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains' },
      { key: 'X-XSS-Protection', value: '1; mode=block' },
      { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'Referrer-Policy', value: 'origin-when-cross-origin' },
      { key: 'Content-Security-Policy', value: "default-src 'self'..." },
    ],
  },
]
```

### A06:2021 – Vulnerable Components

```bash
# Run dependency audit
npm audit --json

# Check for known vulnerabilities
npx snyk test  # If snyk installed

# Check outdated packages
npm outdated --json
```

### A07:2021 – Identification & Authentication Failures

**Check for:**
- [ ] Weak passwords permitted
- [ ] Credential stuffing vulnerability
- [ ] Session fixation
- [ ] Session tokens in URL
- [ ] Missing session timeout
- [ ] Remember me insecure

### A08:2021 – Software & Data Integrity Failures

**Check for:**
- [ ] Unsigned updates
- [ ] CI/CD pipeline vulnerabilities
- [ ] Deserialization vulnerabilities
- [ ] Missing integrity verification

### A09:2021 – Security Logging & Monitoring Failures

**Check for:**
- [ ] Failed login attempts not logged
- [ ] No audit trail for sensitive actions
- [ ] Logs not protected
- [ ] No alerting for suspicious activity

### A10:2021 – Server-Side Request Forgery (SSRF)

**See API7:2023 above for detailed SSRF checks.**

```bash
# Find SSRF vectors
grep -rn "fetch.*\$\{" --include="*.ts"
grep -rn "axios.*\$\{" --include="*.ts"
grep -rn "url.*req\." --include="*.ts"
```

---

## PHASE 6: BUG RISK ANALYSIS

### 5.1 Type Safety Issues

```bash
# Find 'any' types
grep -rn ": any\|as any" --include="*.ts" --include="*.tsx"

# Find type assertions that might fail
grep -rn "as [A-Z]" --include="*.ts" | grep -v "import\|type\|interface"
```

### 5.2 Null/Undefined Handling

```bash
# Find risky property access
grep -rn "\.\w\+\.\w\+" --include="*.ts" | grep -v "\?\." | head -50

# Find missing optional chaining
grep -rn "\.length\|\.map\|\.filter" --include="*.tsx" | grep -v "\?\."
```

### 5.3 Race Conditions

**Check for:**
- [ ] Read-modify-write without transactions
- [ ] Concurrent state updates
- [ ] Missing database locks
- [ ] Async operations without proper sequencing

### 5.4 Resource Leaks

**Check for:**
- [ ] Database connections not released
- [ ] File handles not closed
- [ ] Event listeners not removed
- [ ] Timers not cleared
- [ ] Subscriptions not unsubscribed

### 5.5 Error Handling

```bash
# Find unhandled promises
grep -rn "\.then(" --include="*.ts" | grep -v "\.catch\|await"

# Find empty catch blocks
grep -rn "catch.*{}" --include="*.ts"
grep -rn "catch.*{\s*}" --include="*.ts"
```

---

## PHASE 7: COMPLIANCE CHECKS

### GDPR Compliance (EU)

- [ ] Privacy policy present and linked
- [ ] Cookie consent mechanism
- [ ] Data export functionality (Right to portability)
- [ ] Data deletion functionality (Right to erasure)
- [ ] Consent management for processing
- [ ] Data breach notification process
- [ ] DPO contact information (if required)

### SOC 2 Type II

- [ ] Access controls documented
- [ ] Encryption at rest and in transit
- [ ] Audit logging enabled
- [ ] Incident response plan
- [ ] Vendor management process
- [ ] Change management process

### PCI-DSS (if handling payments)

- [ ] No card data stored (use Stripe/similar)
- [ ] TLS 1.2+ enforced
- [ ] WAF in place
- [ ] Penetration testing scheduled
- [ ] Access logging enabled

### HIPAA (if healthcare data)

- [ ] BAA with all vendors
- [ ] PHI encrypted at rest
- [ ] Access audit logs
- [ ] Minimum necessary access
- [ ] Breach notification process

---

## PHASE 8: AUTOMATED SCANNING

### Run These Commands

```bash
# 1. Dependency vulnerabilities
npm audit --json > docs/security/npm-audit.json

# 2. TypeScript strict mode check
npx tsc --noEmit --strict 2> docs/security/type-errors.txt

# 3. ESLint security rules
npx eslint . --ext .ts,.tsx --format json > docs/security/eslint-report.json

# 4. Find hardcoded secrets
grep -rn "password.*=.*['\"]" --include="*.ts" > docs/security/secrets-scan.txt
grep -rn "api.*key.*=.*['\"]" --include="*.ts" >> docs/security/secrets-scan.txt
grep -rn "secret.*=.*['\"]" --include="*.ts" >> docs/security/secrets-scan.txt

# 5. Find exposed environment variables
grep -rn "NEXT_PUBLIC_\|EXPO_PUBLIC_" --include="*.ts" --include="*.tsx" > docs/security/env-exposure.txt
```

---

## PHASE 9: SEVERITY CLASSIFICATION

### Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| **CRITICAL** | Immediate exploitation possible, data breach risk | < 24 hours |
| **HIGH** | Significant vulnerability, requires specific conditions | < 1 week |
| **MEDIUM** | Limited impact or requires chained exploits | < 1 month |
| **LOW** | Minor issue, best practice violation | Next release |
| **INFO** | Recommendation, no immediate risk | Backlog |

### CVSS Scoring (Simplified)

```
CRITICAL (9.0-10.0): Remote code execution, SQL injection, auth bypass
HIGH (7.0-8.9):      Stored XSS, privilege escalation, data exposure
MEDIUM (4.0-6.9):    Reflected XSS, info disclosure, CSRF
LOW (0.1-3.9):       Missing headers, verbose errors, minor info leak
```

---

## PHASE 10: DELIVERABLES

Generate these files in `docs/security/`:

### 9.1 security-audit-report.md

```markdown
# Security Audit Report

**Date:** YYYY-MM-DD
**Scope:** [Full/Auth/API/Data/Deps/Compliance]
**Auditor:** Claude (AI-Assisted)

## Executive Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | X | 🔴 Immediate |
| High | X | 🟠 Urgent |
| Medium | X | 🟡 Planned |
| Low | X | 🟢 Backlog |

**Overall Security Posture:** [Critical/Poor/Fair/Good/Excellent]

## Critical Findings

### [CRIT-001] Title
- **Location:** `path/to/file.ts:123`
- **Description:** What the vulnerability is
- **Impact:** What an attacker could do
- **CVSS:** 9.5
- **CWE:** CWE-89 (SQL Injection)
- **Remediation:** How to fix
- **Code Example:**
  ```typescript
  // Vulnerable
  ...
  // Secure
  ...
  ```

## High Risk Findings
[Same format as Critical]

## Medium Risk Findings
[Same format]

## Low Risk Findings
[Same format]

## Compliance Status

| Requirement | Status | Notes |
|-------------|--------|-------|
| GDPR | ✅/⚠️/❌ | ... |
| SOC 2 | ✅/⚠️/❌ | ... |

## Recommendations

1. **Immediate:** [Critical fixes]
2. **Short-term:** [High fixes]
3. **Medium-term:** [Security hardening]
4. **Long-term:** [Architecture improvements]
```

### 9.2 bug-risk-report.md

```markdown
# Bug Risk Analysis Report

**Date:** YYYY-MM-DD

## Summary

| Category | High Risk | Medium Risk | Low Risk |
|----------|-----------|-------------|----------|
| Type Safety | X | X | X |
| Null Handling | X | X | X |
| Error Handling | X | X | X |
| Race Conditions | X | X | X |
| Resource Leaks | X | X | X |

## High Risk Areas

### [BUG-001] Title
- **Location:** `path/to/file.ts:123`
- **Issue:** What could fail
- **Trigger:** How it would fail
- **Impact:** What happens when it fails
- **Fix:** How to prevent

## Code Quality Metrics

- TypeScript strict mode: ✅/❌
- Any types found: X
- Unhandled promises: X
- Empty catch blocks: X
```

### 9.3 remediation-roadmap.md

```markdown
# Security Remediation Roadmap

## Immediate (24-48 hours)
- [ ] CRIT-001: Fix SQL injection in /api/users
- [ ] CRIT-002: Remove exposed API key

## Short-term (1-2 weeks)
- [ ] HIGH-001: Add rate limiting to auth endpoints
- [ ] HIGH-002: Implement CSRF protection

## Medium-term (1 month)
- [ ] MED-001: Add security headers
- [ ] MED-002: Implement audit logging

## Long-term (Quarterly)
- [ ] Architecture: Implement proper RBAC
- [ ] Infrastructure: Add WAF
- [ ] Process: Schedule penetration testing
```

### 9.4 priority-matrix.md

```markdown
# Issue Priority Matrix

| ID | Issue | Severity | Effort | Priority | Assignee |
|----|-------|----------|--------|----------|----------|
| CRIT-001 | SQL Injection | Critical | Low | P0 | |
| CRIT-002 | Exposed Secret | Critical | Low | P0 | |
| HIGH-001 | Missing Rate Limit | High | Medium | P1 | |
| HIGH-002 | No Auth on /api/x | High | Low | P1 | |

**Priority Formula:**
- P0: Critical + Any Effort
- P1: High + Low/Medium Effort
- P2: High + High Effort OR Medium + Low Effort
- P3: Medium + Medium/High Effort
- P4: Low + Any Effort
```

---

## PHASE 11: KNOWLEDGE UPDATE

### Update DONT_DO.md

Add discovered vulnerabilities as anti-patterns:

```markdown
## YYYY-MM-DD | SECURITY

### ❌ [Vulnerability pattern discovered]

**Context:** What triggered the audit finding
**Tried:** What insecure pattern was found
**Result:** Potential security impact
**Root Cause:** Why this pattern is vulnerable
**✅ Solution:** Secure alternative pattern
**Prevention:** How to prevent in future
```

### Update CRITICAL_NOTES.md

Add security requirements:

```markdown
## 🔐 Security Requirements

### Authentication
- All API routes MUST check auth() before any operation
- Use middleware.ts for route protection patterns

### Data Protection
- NEVER use NEXT_PUBLIC_ with secrets
- All user input MUST be validated with Zod

### [Other requirements discovered during audit]
```

### Update progress.txt

Log the audit:

```markdown
## YYYY-MM-DD HH:MM - Security Audit ([scope])
- Findings: X critical, X high, X medium, X low
- Key issues: [brief list]
- Reports generated in docs/security/
- **Learnings:** [patterns discovered]
```

---

## OUTPUT STRUCTURE

```
docs/security/
├── security-audit-report.md    # Main findings
├── bug-risk-report.md          # Code quality issues
├── remediation-roadmap.md      # Action plan
├── priority-matrix.md          # Issue prioritization
├── npm-audit.json              # Raw npm audit output
├── eslint-report.json          # ESLint findings
└── scans/                      # Raw scan outputs
    ├── secrets-scan.txt
    ├── env-exposure.txt
    └── type-errors.txt
```

---

## QUICK REFERENCE: Red Flags to Always Report

```
🚩 CRITICAL - Report Immediately:
- API keys in client code (NEXT_PUBLIC_*, EXPO_PUBLIC_*)
- SQL queries with string concatenation
- Missing auth on data-modifying endpoints
- Direct database access from frontend
- Hardcoded secrets in code
- dangerouslySetInnerHTML with user content

🚩 HIGH - Report Same Day:
- Missing rate limiting on auth endpoints
- No input validation on user data
- Client-side price/permission calculations
- Session tokens in URLs
- Missing HTTPS enforcement
- CORS: Access-Control-Allow-Origin: *

🚩 MEDIUM - Report This Sprint:
- Missing security headers
- Verbose error messages to client
- Outdated dependencies with CVEs
- No audit logging
- Weak password requirements
```

---

## MOBILE PLATFORM

> Mobile Security = App + Data + Platform

### Mobile-Specific Agents

```yaml
Agents:
  Lead: security              # Security specialist
  Consult:
    - mobile-rn               # React Native specifics
    - mobile-ios              # iOS security
    - mobile-android          # Android security
    - mobile-release          # Store compliance
```

### Secure Storage Audit

```bash
# Find AsyncStorage usage with sensitive data
grep -r "AsyncStorage.*token\|AsyncStorage.*password\|AsyncStorage.*key" src/

# Find console.log with sensitive data
grep -r "console.log.*token\|console.log.*password\|console.log.*user" src/

# Find hardcoded secrets
grep -r "apiKey.*=.*['\"]" src/
grep -r "secret.*=.*['\"]" src/
```

### Storage Security

```typescript
// CRITICAL: Sensitive data in AsyncStorage
import AsyncStorage from '@react-native-async-storage/async-storage'
await AsyncStorage.setItem('auth_token', token) // Unencrypted!

// SECURE: Use SecureStore
import * as SecureStore from 'expo-secure-store'
await SecureStore.setItemAsync('auth_token', token) // Encrypted
```

| Check | Status |
|-------|--------|
| Tokens in SecureStore | |
| No sensitive data in AsyncStorage | |
| No hardcoded secrets | |
| No API keys in code | |
| No sensitive data in logs | |

### Network Security

```typescript
// CRITICAL: HTTP (not HTTPS)
const API_URL = 'http://api.example.com'

// SECURE: HTTPS only
const API_URL = 'https://api.example.com'
```

#### Certificate Pinning (High Security)

```typescript
import { TrustKit } from 'react-native-trustkit'

TrustKit.initialize({
  'api.example.com': {
    pinnedDomains: ['api.example.com'],
    publicKeyHashes: ['AAAA...', 'BBBB...'],
  },
})
```

### Biometric Authentication

```typescript
// Biometric without proper checks
const auth = await LocalAuthentication.authenticateAsync()

// Proper biometric implementation
const hasHardware = await LocalAuthentication.hasHardwareAsync()
const enrolled = await LocalAuthentication.isEnrolledAsync()

if (hasHardware && enrolled) {
  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: 'Verify your identity',
    fallbackLabel: 'Use passcode',
    cancelLabel: 'Cancel',
  })
}
```

### Session Management

```typescript
// Token never expires
const token = await SecureStore.getItemAsync('token')

// Token with expiry check
const tokenData = JSON.parse(await SecureStore.getItemAsync('token_data'))
if (tokenData.expiresAt < Date.now()) {
  await refreshToken()
}
```

### Deep Link Security

```typescript
// Unvalidated deep link
export function handleDeepLink(url: string) {
  const { path, params } = parseURL(url)
  navigate(path, params) // Could navigate anywhere!
}

// Validated deep link
const ALLOWED_PATHS = ['/product', '/category', '/profile']

export function handleDeepLink(url: string) {
  const { path, params } = parseURL(url)

  if (!ALLOWED_PATHS.includes(path)) {
    console.warn('Invalid deep link path')
    return
  }

  // Validate params
  if (path === '/product' && !isValidProductId(params.id)) {
    return
  }

  navigate(path, params)
}
```

### Platform Security

#### iOS-Specific

```typescript
// Jailbreak detection (optional)
import JailMonkey from 'jail-monkey'
if (JailMonkey.isJailBroken()) {
  // Handle jailbroken device
}

// Prevent screenshots
import { usePreventScreenCapture } from 'expo-screen-capture'
usePreventScreenCapture()
```

#### Android-Specific

```typescript
// Root detection (optional)
import JailMonkey from 'jail-monkey'
if (JailMonkey.isRooted()) {
  // Handle rooted device
}
```

### App Store Compliance

#### iOS App Store
- [ ] No private API usage
- [ ] Privacy manifest (PrivacyInfo.xcprivacy)
- [ ] App Tracking Transparency (if tracking)
- [ ] No remote code execution
- [ ] Proper data handling disclosures

#### Google Play
- [ ] Privacy policy linked
- [ ] Data safety section complete
- [ ] Permissions justified
- [ ] No deceptive behavior
- [ ] Target API level compliance

### Mobile Security Checklist

```markdown
### Data Storage
- [ ] Tokens in SecureStore (not AsyncStorage)
- [ ] No sensitive data in logs
- [ ] No hardcoded secrets
- [ ] API keys not in code

### Network
- [ ] HTTPS only
- [ ] Certificate pinning (if high security)
- [ ] API authentication on all requests

### Authentication
- [ ] Biometrics properly implemented
- [ ] Session expiry handled
- [ ] Secure logout (clear tokens)

### Platform
- [ ] iOS: Privacy manifest present
- [ ] Android: Data safety complete
- [ ] Deep links validated
- [ ] Screenshot prevention (if needed)

### Dependencies
- [ ] npm audit clean
- [ ] Expo SDK up to date
- [ ] No known vulnerable packages
```

### Mobile Audit Report Template

```markdown
## Mobile Security Audit Report

### Executive Summary
- Overall security: [Good/Fair/Poor]
- Critical issues: [X]
- High issues: [X]
- Medium issues: [X]

### Critical Findings
| Issue | Impact | Remediation |
|-------|--------|-------------|
| [Finding] | [Impact] | [Fix] |

### Platform Compliance
- iOS: [Ready/Not Ready]
- Android: [Ready/Not Ready]

### Recommendations
1. [Priority 1 - Critical]
2. [Priority 2 - High]
3. [Priority 3 - Medium]
```

---
name: input-validation
description: Use when validating user input, forms, or API data. Zod, validation patterns. Triggers on: validation, validate, input, form validation, zod, schema, sanitize.
version: 1.0.0
detect: ["security-audit"]
---

# Input Validation & Injection Prevention

Comprehensive input validation and injection attack prevention.

## SQL Injection

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Direct string interpolation
const query = `SELECT * FROM users WHERE email = '${email}'`
await db.$queryRawUnsafe(query)

// ❌ CRITICAL: Template literal without parameterization
await db.$queryRaw`SELECT * FROM users WHERE email = ${email}` // Still vulnerable!

// ❌ CRITICAL: Raw query building
const orderBy = req.query.sort // user input: "name; DROP TABLE users;--"
await db.$queryRaw(`SELECT * FROM posts ORDER BY ${orderBy}`)
```

### Secure Patterns

```typescript
// ✅ SECURE: Use ORM methods
const user = await db.user.findUnique({
  where: { email }
})

// ✅ SECURE: Parameterized raw queries (when ORM won't work)
await db.$queryRaw`
  SELECT * FROM users WHERE email = ${email}::text
`

// ✅ SECURE: Whitelist for dynamic columns
const ALLOWED_SORT_COLUMNS = ['name', 'createdAt', 'email'] as const
const sortColumn = ALLOWED_SORT_COLUMNS.includes(req.query.sort as any)
  ? req.query.sort
  : 'createdAt'

await db.user.findMany({
  orderBy: { [sortColumn]: 'asc' }
})
```

## Cross-Site Scripting (XSS)

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Unescaped user content
<div dangerouslySetInnerHTML={{ __html: userComment }} />

// ❌ CRITICAL: Unvalidated href
<a href={userProvidedUrl}>Click here</a>  // javascript:alert(1)

// ❌ HIGH: Unescaped in script
<script>
  const data = {JSON.stringify(userData)};  // Can break out of JSON
</script>
```

### Secure Patterns

```typescript
// ✅ SECURE: React auto-escapes
<div>{userComment}</div>

// ✅ SECURE: Sanitize HTML if needed
import DOMPurify from 'dompurify'

const sanitizedHtml = DOMPurify.sanitize(userHtml, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
  ALLOWED_ATTR: ['href', 'title'],
})
<div dangerouslySetInnerHTML={{ __html: sanitizedHtml }} />

// ✅ SECURE: Validate URLs
function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url)
    return ['http:', 'https:'].includes(parsed.protocol)
  } catch {
    return false
  }
}

{isValidUrl(userUrl) && <a href={userUrl}>Link</a>}

// ✅ SECURE: JSON in script tag
<script
  type="application/json"
  id="__DATA__"
  dangerouslySetInnerHTML={{
    __html: JSON.stringify(data).replace(/</g, '\\u003c')
  }}
/>
```

## Command Injection

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Direct command execution
import { exec } from 'child_process'

const filename = req.query.file // user input: "file.txt; rm -rf /"
exec(`cat ${filename}`, (err, stdout) => {
  res.send(stdout)
})

// ❌ CRITICAL: Shell expansion
exec(`echo ${userMessage}`) // $(whoami) would execute
```

### Secure Patterns

```typescript
// ✅ SECURE: Use execFile with array arguments
import { execFile } from 'child_process'

execFile('cat', [filename], (err, stdout) => {
  res.send(stdout)
})

// ✅ SECURE: Whitelist allowed values
const ALLOWED_FILES = ['readme.txt', 'help.txt']
if (!ALLOWED_FILES.includes(filename)) {
  return res.status(400).send('Invalid file')
}

// ✅ SECURE: Use libraries instead of shell commands
import fs from 'fs/promises'
const content = await fs.readFile(path.join(SAFE_DIR, filename), 'utf-8')
```

## Path Traversal

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: Direct path concatenation
const filePath = `./uploads/${req.params.filename}`
// filename: "../../../etc/passwd"
const content = await fs.readFile(filePath)

// ❌ CRITICAL: Insufficient validation
const filename = req.params.filename.replace('..', '')
// Can bypass: "....//....//etc/passwd"
```

### Secure Patterns

```typescript
import path from 'path'

// ✅ SECURE: Resolve and validate path
const UPLOADS_DIR = path.resolve('./uploads')

function getSafePath(filename: string): string | null {
  // Remove any path components
  const basename = path.basename(filename)
  
  // Resolve the full path
  const fullPath = path.resolve(UPLOADS_DIR, basename)
  
  // Ensure it's within the uploads directory
  if (!fullPath.startsWith(UPLOADS_DIR)) {
    return null
  }
  
  return fullPath
}

// Usage
const safePath = getSafePath(req.params.filename)
if (!safePath) {
  return res.status(400).send('Invalid filename')
}
const content = await fs.readFile(safePath)
```

## File Upload Security

### Vulnerable Patterns

```typescript
// ❌ CRITICAL: No validation
app.post('/upload', async (req, res) => {
  const file = req.files.file
  await file.mv(`./uploads/${file.name}`) // Can upload .php, .exe, etc.
})

// ❌ HIGH: Extension-only validation
const ext = path.extname(file.name)
if (ext !== '.jpg') throw new Error('Only JPG allowed')
// Can bypass with: malware.php.jpg or null bytes
```

### Secure Patterns

```typescript
import { fileTypeFromBuffer } from 'file-type'
import crypto from 'crypto'

// ✅ SECURE: Comprehensive validation
async function validateUpload(file: Buffer, originalName: string) {
  // 1. Check file size
  const MAX_SIZE = 5 * 1024 * 1024 // 5MB
  if (file.length > MAX_SIZE) {
    throw new Error('File too large')
  }

  // 2. Detect actual file type from content (magic bytes)
  const type = await fileTypeFromBuffer(file)
  
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']
  if (!type || !ALLOWED_TYPES.includes(type.mime)) {
    throw new Error('Invalid file type')
  }

  // 3. Generate safe filename (never use user-provided name)
  const safeFilename = `${crypto.randomUUID()}.${type.ext}`

  // 4. Store outside web root or use CDN
  const uploadPath = path.join(UPLOADS_DIR, safeFilename)
  
  return { uploadPath, safeFilename, mimeType: type.mime }
}
```

## Zod Validation Schemas

```typescript
import { z } from 'zod'

// ✅ Comprehensive input validation
export const userInputSchema = z.object({
  // String validation
  name: z.string()
    .min(1, 'Name is required')
    .max(100, 'Name too long')
    .regex(/^[a-zA-Z\s]+$/, 'Name can only contain letters'),

  // Email validation
  email: z.string()
    .email('Invalid email')
    .toLowerCase(),

  // URL validation
  website: z.string()
    .url('Invalid URL')
    .refine(url => {
      const parsed = new URL(url)
      return ['http:', 'https:'].includes(parsed.protocol)
    }, 'URL must be http or https')
    .optional(),

  // Number validation
  age: z.number()
    .int('Age must be whole number')
    .min(0, 'Age cannot be negative')
    .max(150, 'Invalid age'),

  // Enum validation
  role: z.enum(['user', 'moderator'] as const),

  // Array validation
  tags: z.array(z.string().max(50))
    .max(10, 'Maximum 10 tags'),
})

// Usage in API
export async function POST(req: Request) {
  const body = await req.json()
  
  const result = userInputSchema.safeParse(body)
  if (!result.success) {
    return Response.json(
      { error: 'Validation failed', details: result.error.flatten() },
      { status: 400 }
    )
  }
  
  // Use validated data
  const validatedData = result.data
}
```

## Content Security Policy

```typescript
// next.config.ts
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self' https://api.yourdomain.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
`

// Production-ready CSP (no unsafe-*)
const StrictCSP = `
  default-src 'self';
  script-src 'self';
  style-src 'self';
  img-src 'self' data:;
  font-src 'self';
  connect-src 'self';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
  upgrade-insecure-requests;
`
```

## Audit Checklist

```markdown
## Input Validation Audit

### Critical
- [ ] No SQL injection vulnerabilities (use ORM or parameterized queries)
- [ ] No command injection (use execFile, not exec)
- [ ] No path traversal (validate file paths)
- [ ] File uploads validate content, not just extension

### High
- [ ] All user input validated with Zod/yup
- [ ] No dangerouslySetInnerHTML with user content
- [ ] URLs validated before use in href/src
- [ ] Rate limiting on all public endpoints

### Medium
- [ ] CSP headers configured
- [ ] Input length limits enforced
- [ ] Error messages don't leak internal details

### Low
- [ ] Input sanitization for display
- [ ] Logging of validation failures (for monitoring)
```

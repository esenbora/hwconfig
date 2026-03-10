---
name: security-first
description: Use for any code you write. Security is not optional. Always active.
version: 2.0.0
triggers:
  - always_active
detection_patterns:
  # These patterns trigger security warnings
  critical:
    - "NEXT_PUBLIC_.*KEY|NEXT_PUBLIC_.*SECRET|NEXT_PUBLIC_.*TOKEN"
    - "EXPO_PUBLIC_.*KEY|EXPO_PUBLIC_.*SECRET"
    - "supabase\\.from\\(['\"]\\w+['\"]\\)\\.select|supabase\\.from\\(['\"]\\w+['\"]\\)\\.insert"
    - "firebase\\.firestore\\(\\)\\.collection"
    - "console\\.log\\(.*password|console\\.log\\(.*token|console\\.log\\(.*secret"
  high:
    - "\\$\\{.*\\}.*SELECT|\\$\\{.*\\}.*INSERT|\\$\\{.*\\}.*UPDATE|\\$\\{.*\\}.*DELETE"
    - "innerHTML\\s*=|dangerouslySetInnerHTML"
    - "eval\\(|Function\\("
  medium:
    - "console\\.log\\(.*user|console\\.log\\(.*response"
    - "localStorage\\.setItem\\(['\"].*token|AsyncStorage\\.setItem\\(['\"].*token"
---

# Security-First Development

> Security is not optional. Every feature, every line of code.
> 80%+ of vibe-coded apps have critical vulnerabilities. Don't be one of them.

---

## Auto-Detection Integration

This skill automatically scans code for security issues:

**CRITICAL (Block):**
- API keys in NEXT_PUBLIC_/EXPO_PUBLIC_ variables
- Direct Supabase/Firebase client queries for sensitive data
- Sensitive data in console.log

**HIGH (Warn):**
- SQL string concatenation (injection risk)
- innerHTML/dangerouslySetInnerHTML (XSS risk)
- eval() or Function() (code injection)

**MEDIUM (Note):**
- User objects in console.log
- Tokens in localStorage/AsyncStorage

When detected, the pre-edit hook will prompt for security review.

---

## 🚨 THE 12 VIBE-CODING SECURITY RULES

### 1. Don't Talk to Database Directly
```
❌ BAD:  Frontend → Database (Supabase/Firebase direct)
✅ GOOD: Frontend → API/Middleware → Database

AI often connects frontend straight to database.
This is leaving your front door open.
ALWAYS use a backend API layer.
```

### 2. Gatekeep EVERY Action
```
❌ BAD:  Check auth once at login
✅ GOOD: Check auth + permissions at EVERY endpoint

Just because user is logged in doesn't mean they can do everything.
Check ID badge at EVERY high-security door, not just the entrance.

// Every endpoint needs this:
if (!user) return unauthorized();
if (!user.canAccess(resource)) return forbidden();
```

### 3. Don't Hide, WITHHOLD
```
❌ BAD:  Ask "is premium?" → Hide button if no
✅ GOOD: Only DELIVER premium content after server verification

Users can change client-side "no" to "yes" easily.
Premium check MUST happen server-side before sending data.

// Bad
const isPremium = await checkPremium();
if (isPremium) showPremiumButton();

// Good
// Server only returns premium data if user is verified premium
const data = await api.getPremiumContent(); // Server checks internally
```

### 4. Keep Secrets OFF the Browser
```
❌ BAD:  API keys in client code (even with NEXT_PUBLIC_)
✅ GOOD: API keys ONLY on server

If it's on their screen, it's in their pocket.
OpenAI, Stripe, any API key = SERVER ONLY.

// Never this in client code:
const openai = new OpenAI({ apiKey: process.env.NEXT_PUBLIC_OPENAI_KEY });

// Always this via server:
// app/api/generate/route.ts (server-side)
const openai = new OpenAI({ apiKey: process.env.OPENAI_KEY });
```

### 5. .env Doesn't Mean Safe
```
❌ MYTH: ".env keeps my keys safe"
✅ TRUTH: .env only prevents git push, NOT client exposure

NEXT_PUBLIC_* = EXPOSED to client
EXPO_PUBLIC_* = EXPOSED to client

Only non-prefixed env vars stay server-side.
```

### 6. Don't Do Math on the Phone
```
❌ BAD:  Calculate prices/scores on client
✅ GOOD: All sensitive calculations on SERVER

If logic lives on their device, they can change the math.

// Bad - client calculates price
const total = items.reduce((sum, i) => sum + i.price, 0);
const discount = isPremium ? 0.2 : 0;
const final = total * (1 - discount);

// Good - server calculates
const { finalPrice } = await api.calculateOrder(items);
```

### 7. Sanitize EVERYTHING
```
❌ BAD:  Trust user input
✅ GOOD: Sanitize ALL inputs, treat as hostile

Weird code in a comment box can break your database (SQL injection, XSS).

// Always sanitize
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);

// Always use parameterized queries
await db.query('SELECT * FROM users WHERE id = $1', [userId]);
// NEVER: `SELECT * FROM users WHERE id = ${userId}`
```

### 8. Rate Limit EVERYTHING
```
❌ BAD:  No limits on actions
✅ GOOD: Rate limit all expensive operations

Without limits, bots click "send email" 1000x/second.
This crashes your app AND costs you money.

// Add to every API route
import { ratelimit } from '@/lib/ratelimit';

const { success } = await ratelimit.limit(userId);
if (!success) return tooManyRequests();
```

### 9. Don't Log Sensitive Stuff
```
❌ BAD:  console.log(user) // includes password hash, tokens
✅ GOOD: Log only safe fields

AI debugging often logs EVERYTHING.
Check logs don't contain: passwords, tokens, emails, API keys.

// Bad
console.log('User:', user);

// Good
console.log('User:', { id: user.id, role: user.role });
```

### 10. Audit with a Rival AI
```
When you code with Claude, audit with Gemini/GPT.
Different models catch different vulnerabilities.

Prompt: "Audit this code for security vulnerabilities. 
Be thorough. Check for OWASP top 10, auth bypasses, 
injection attacks, and data exposure."
```

### 11. Keep Dependencies Updated
```
Old versions have known exploits hackers use.
Regular updates patch security holes.

# Check for vulnerabilities
npm audit
npx snyk test

# Update safely
npx npm-check-updates -u
npm update
```

### 12. Error Handling Without Secrets
```
❌ BAD:  Error shows database details, stack traces
✅ GOOD: Vague errors for users, detailed logs privately

// Bad - exposes internals
return res.status(500).json({ 
  error: 'PostgreSQL connection failed at 192.168.1.1:5432' 
});

// Good - safe for users
return res.status(500).json({ error: 'Something went wrong' });
// Log details server-side only
console.error('DB Error:', error); // Goes to server logs, not client
```

---

## Quick Checklist Before Every Feature

```
□ Database access through API, not direct?
□ Auth checked at every endpoint?
□ Premium features verified server-side?
□ API keys only on server (no NEXT_PUBLIC_)?
□ Sensitive calculations on server?
□ All inputs sanitized?
□ Rate limiting on expensive operations?
□ No sensitive data in logs?
□ Dependencies up to date?
□ Error messages don't leak internals?
```

---

## Red Flags to Watch For

When AI generates code, STOP if you see:

```
🚩 Direct Supabase/Firebase client queries for sensitive data
🚩 NEXT_PUBLIC_ or EXPO_PUBLIC_ with API keys
🚩 Price calculations in React components
🚩 if (isPremium) showContent() without server check
🚩 console.log(user) or console.log(response)
🚩 String concatenation in SQL queries
🚩 No rate limiting on API routes
🚩 Detailed error messages returned to client
```

---

## Security-First Means

```
1. Assume the client is compromised
2. Verify everything server-side
3. Trust nothing from the browser
4. Log nothing sensitive
5. Update everything regularly
6. Audit with multiple tools/AIs
```

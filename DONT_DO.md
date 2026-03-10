# DONT_DO - Failed Approaches Log

> Check this file BEFORE solving problems to avoid repeating mistakes.
> Claude will automatically add entries when patterns are learned.

---

## Template

```markdown
## YYYY-MM-DD | CATEGORY

### ❌ Short description

**Context:** What you were trying to do
**Tried:** What approach was attempted
**Result:** What went wrong
**Root Cause:** Why it didn't work
**✅ Solution:** What actually works
**Prevention:** How to avoid in future
```

---

## Common Patterns (Pre-loaded)

### TYPESCRIPT

**❌ Don't:** Edit code without verifying type definitions
**✅ Do:** Read type/interface before using properties, run `npx tsc --noEmit`

### VERIFICATION

**❌ Don't:** Claim "done" without running verification commands
**✅ Do:** Run tests/build/lint, show actual output, THEN claim result

### SECURITY

**❌ Don't:** Use `NEXT_PUBLIC_` with API keys
**✅ Do:** Keep secrets server-side only, use API routes to proxy

### DATABASE

**❌ Don't:** Connect frontend directly to database
**✅ Do:** Frontend → API Route → Database (always)

### VISUAL/LAYOUT

**❌ Don't:** Implement layouts based on text description alone
**✅ Do:** Request Figma/screenshot first, verify visually

---

## Your Entries

<!-- Claude will add learned patterns specific to your projects here -->

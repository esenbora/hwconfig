---
name: llm-security
description: Use when building AI features that need security. Prompt injection, output sanitization. Triggers on: llm security, prompt injection, ai security, jailbreak, prompt attack.
version: 1.0.0
context: fork
agent: security
---

# LLM Security

Security patterns for AI/LLM integrations in applications.

## Core Principles

1. Never trust LLM output for security decisions
2. Sanitize all LLM outputs before rendering
3. Rate limit and cost cap all AI endpoints
4. Log all AI interactions for audit
5. Validate inputs before sending to LLM

## Input Validation

```typescript
// Sanitize user input before LLM
function sanitizeForLLM(input: string): string {
  // Remove potential injection patterns
  const cleaned = input
    .replace(/ignore (previous|all) instructions/gi, '')
    .replace(/you are now/gi, '')
    .replace(/system:/gi, '')
    .slice(0, 4000) // Token limit

  return cleaned
}
```

## Output Sanitization

```typescript
// Never trust LLM output
function sanitizeLLMOutput(output: string): string {
  // Escape HTML to prevent XSS
  return DOMPurify.sanitize(output)
}

// Never use LLM output for:
// - SQL queries (injection risk)
// - System commands (RCE risk)
// - File paths (traversal risk)
// - Authentication decisions
```

## Rate Limiting & Cost Control

```typescript
// Rate limit AI endpoints aggressively
const aiRateLimit = ratelimit({
  window: '1m',
  max: 10,  // 10 requests per minute
})

// Cost tracking per user
async function trackAICost(userId: string, tokens: number) {
  const cost = tokens * 0.00002  // Approximate cost
  await db.user.update({
    where: { id: userId },
    data: { aiSpend: { increment: cost } }
  })
}
```

## Anti-Patterns

- Trusting LLM output for auth/security decisions
- No rate limiting on AI endpoints
- Rendering LLM output without sanitization
- No cost tracking or limits
- Exposing system prompts to users

---
name: mcp-security
description: Use when working with MCP servers or tools. Server authentication, tool permissions. Triggers on: mcp, mcp server, mcp security, tool permission.
version: 1.0.0
---

# MCP Security

Security patterns for Model Context Protocol implementations.

## Core Principles

1. Validate all tool inputs
2. Authenticate MCP connections
3. Limit resource access scope
4. Audit all tool invocations
5. Sanitize tool outputs

## Tool Input Validation

```typescript
// Always validate tool parameters
const toolSchema = z.object({
  action: z.enum(['read', 'write', 'delete']),
  path: z.string().refine(path => {
    // Prevent path traversal
    return !path.includes('..') && path.startsWith('/allowed/')
  }),
  data: z.string().max(10000).optional()
})

async function handleTool(params: unknown) {
  const validated = toolSchema.parse(params)
  // Now safe to use
}
```

## Connection Authentication

```typescript
// Authenticate MCP transport
const mcpServer = new MCPServer({
  transport: 'http',
  auth: {
    type: 'bearer',
    validate: async (token) => {
      const valid = await verifyToken(token)
      if (!valid) throw new Error('Unauthorized')
    }
  }
})
```

## Resource Access Control

```typescript
// Scope resources per user/session
function getResources(userId: string) {
  return {
    // Only expose user's own resources
    files: getUserFiles(userId),
    database: scopedDbAccess(userId),
  }
}
```

## Audit Logging

```typescript
// Log all tool invocations
async function auditToolUse(tool: string, params: any, result: any) {
  await db.auditLog.create({
    data: {
      tool,
      params: JSON.stringify(params),
      resultSummary: summarize(result),
      timestamp: new Date()
    }
  })
}
```

## Anti-Patterns

- No input validation on tools
- Unauthenticated MCP connections
- Exposing full filesystem/database
- No audit trail for tool usage
- Trusting tool outputs blindly

# 📁 Directory Knowledge - AGENTS.md

> **Purpose:** Per-directory knowledge for AI agents and developers.
> **Location:** Place in directories with non-obvious patterns.
> **Rule:** Update when discovering reusable knowledge about this directory.

---

## 📍 Directory: [path/to/directory]

### Purpose
<!-- What is this directory for? -->

### Patterns
<!-- Patterns specific to this directory -->

- Pattern 1: Description
- Pattern 2: Description

### Dependencies
<!-- What other parts of the codebase does this depend on? -->

- Depends on: `../lib/utils`
- Used by: `../components/`

### Gotchas
<!-- Non-obvious things about this directory -->

- Gotcha 1: Description and how to handle
- Gotcha 2: Description and how to handle

### Testing
<!-- How to test code in this directory -->

- Test file location: `__tests__/`
- Required setup: Description
- Environment variables needed: List

### Examples
<!-- Example usage or patterns -->

```typescript
// How to use the main export
import { something } from './index'

something({ config: 'value' })
```

---

## 🔄 Update Log

| Date | Change |
|------|--------|
| YYYY-MM-DD | Initial creation |

---

## Template for New AGENTS.md

Copy this template when creating AGENTS.md in a new directory:

```markdown
# 📁 [Directory Name]

## Purpose
[What this directory contains and why]

## Patterns
- [Pattern 1]
- [Pattern 2]

## Gotchas
- [Non-obvious thing 1]
- [Non-obvious thing 2]

## Testing
- Test location: `__tests__/`
- Run: `npm test -- [pattern]`
```


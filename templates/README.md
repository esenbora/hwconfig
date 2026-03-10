# Request Templates

> Copy-paste templates for common requests to improve one-shot success.

## How to Use

1. Copy the relevant template
2. Fill in the brackets [like this]
3. Paste to Claude

---

## Feature Request

```
Build [feature name]

Context:
- App: [web/mobile/both]
- Stack: [Next.js/Expo/etc]
- Related files: [paths if known]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Acceptance Criteria:
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

Design Reference: [Figma link / screenshot path]
```

---

## Bug Fix

```
Fix: [Short description]

Expected: [What should happen]
Actual: [What's happening]

Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Error Message: [If any]
Related Files: [paths if known]
Recent Changes: [What changed before bug appeared]
```

---

## Performance Issue

```
Optimize: [What's slow]

Current State:
- [Metric]: [Current value] (e.g., "Page load: 5s")
- Frequency: [How often it happens]

Target:
- [Metric]: [Target value] (e.g., "Page load: <1s")

Affected Area:
- [Files/endpoints/queries]

Already Tried: [List any previous attempts]
```

---

## Refactor Request

```
Refactor: [What to refactor]

Current Problems:
- [Problem 1]
- [Problem 2]

Goals:
- [Goal 1: e.g., "Improve readability"]
- [Goal 2: e.g., "Remove duplication"]

Constraints:
- [ ] Must maintain current functionality
- [ ] Tests must pass
- [ ] No breaking API changes

Files: [paths]
```

---

## API Endpoint

```
Create API: [METHOD] /api/[path]

Purpose: [What it does]

Input:
```json
{
  "field1": "type",
  "field2": "type"
}
```

Output:
```json
{
  "field1": "type",
  "field2": "type"
}
```

Auth: [Required/Optional/None]
Rate Limit: [requests per minute]
Related: [Other endpoints it interacts with]
```

---

## Component Request

```
Create Component: [ComponentName]

Purpose: [What it does]

Props:
- [propName]: [type] - [description]
- [propName]: [type] - [description]

States:
- [State 1: e.g., "loading", "error", "success"]

Design:
- [Figma/screenshot/description]
- Mobile responsive: [yes/no]

Similar to: [Existing component for reference]
```

---

## Database Schema

```
Add Schema: [table/model name]

Purpose: [What data it stores]

Fields:
- [fieldName]: [type] - [description]
- [fieldName]: [type] - [description]

Relations:
- [Related table]: [relation type] (e.g., "users: one-to-many")

Indexes:
- [Field(s) to index]

Constraints:
- [Unique fields]
- [Required fields]
```

---

## Integration Request

```
Integrate: [Service name]

Purpose: [Why we need it]

Use Cases:
1. [Use case 1]
2. [Use case 2]

API Keys Needed:
- [Key name]: [Where to get it]

Endpoints to Use:
- [Endpoint 1]: [What for]
- [Endpoint 2]: [What for]

Error Handling:
- [What to do on failure]

Existing Docs: [Link if available]
```

---

## Deployment Request

```
Deploy: [What to deploy]

Environment: [staging/production]

Pre-deployment:
- [ ] Tests passing
- [ ] Migrations ready
- [ ] Environment variables set

Changes Include:
- [Change 1]
- [Change 2]

Rollback Plan: [How to rollback if needed]

Notify: [Who to notify]
```

---

## Quick Patterns

### Simple Fix
```
Fix [brief description] in [file path]
```

### Simple Add
```
Add [what] to [where]
```

### Simple Change
```
Change [what] from [old] to [new] in [where]
```

### Simple Remove
```
Remove [what] from [where]
```

---

## Tips for Better Requests

1. **Be specific** - "Add auth" → "Add Clerk auth with Google OAuth"
2. **Show context** - Include file paths, related code
3. **Define done** - What does success look like?
4. **One thing at a time** - Split large requests
5. **Include examples** - Reference existing patterns

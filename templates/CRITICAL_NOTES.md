# ⚡ CRITICAL NOTES - Project Knowledge Base

> **Purpose:** Essential project-specific knowledge that MUST be followed.
> **Rule:** Read this file at the START of every session.
> **Update:** Add entries for non-obvious requirements, gotchas, and patterns.

---

## 🏗️ Architecture Decisions

<!-- Document key architecture choices and WHY -->

### Example Entry
```markdown
### Database: PostgreSQL with Prisma
**Decision:** Using Prisma ORM over Drizzle
**Reason:** Team familiarity, better migration tooling
**Trade-off:** Slightly larger bundle, but worth it for DX
**Date:** 2026-01-13
```

---

## 🔧 Project-Specific Patterns

<!-- Document patterns unique to THIS project -->

### Naming Conventions
- Components: PascalCase (`UserCard.tsx`)
- Hooks: camelCase with `use` prefix (`useUserData.ts`)
- Server Actions: camelCase with action suffix (`createUserAction.ts`)
- API Routes: kebab-case (`/api/user-profile`)

### File Organization
```
src/
├── app/              # Next.js App Router
├── components/       # Shared components
│   ├── ui/          # shadcn/ui components
│   └── features/    # Feature-specific components
├── lib/             # Utilities, clients
├── hooks/           # Custom React hooks
├── actions/         # Server actions
└── types/           # TypeScript types
```

### Component Structure
```tsx
// Standard component structure for this project
'use client' // Only if needed

import { ... } from 'react'
import { cn } from '@/lib/utils'

interface Props { ... }

export function ComponentName({ ...props }: Props) {
  // hooks first
  // derived state
  // handlers
  // return JSX
}
```

---

## ⚠️ Gotchas & Non-Obvious Requirements

<!-- Things that WILL bite you if you don't know -->

### Example
```markdown
### Server Actions Must Return Plain Objects
**Gotcha:** Can't return class instances or functions from server actions
**Symptom:** "Error: Only plain objects can be passed to Client Components"
**Fix:** Always serialize to plain objects: `return { ...instance }`
```

---

## 🔐 Security Requirements

<!-- Security rules specific to this project -->

- [ ] All user input validated with Zod
- [ ] Server actions check authentication
- [ ] Sensitive data never logged
- [ ] Environment variables never exposed to client

---

## 📦 Dependencies & Versions

<!-- Critical version requirements -->

| Package | Version | Notes |
|---------|---------|-------|
| Next.js | 14.x | App Router required |
| React | 18.x | Concurrent features |
| TypeScript | 5.x | Strict mode |

---

## 🚀 Deployment Requirements

<!-- Deployment-specific knowledge -->

- **Platform:** Vercel
- **Environment Variables:** See `.env.example`
- **Build Command:** `npm run build`
- **Required Secrets:** `DATABASE_URL`, `NEXTAUTH_SECRET`

---

## 📝 Update Log

| Date | Author | Change |
|------|--------|--------|
| 2026-01-13 | Setup | Initial template |


---
name: monorepo
description: Use when working with monorepos, workspaces, or multi-package projects. pnpm workspaces, Turborepo, NX patterns. Triggers on: monorepo, workspace, turborepo, turbo, nx, pnpm workspace, multi-package, shared packages, internal packages.
version: 1.0.0
---

# Monorepo Patterns

> Scalable monorepo architecture with pnpm workspaces, Turborepo, and NX.

---

## Quick Reference

```bash
# pnpm workspace commands
pnpm -w <cmd>                    # Run in root
pnpm --filter <pkg> <cmd>        # Run in specific package
pnpm --filter "./apps/*" <cmd>   # Run in all apps
pnpm --filter "...[origin/main]" # Changed packages only

# Turborepo commands
turbo run build                  # Build all packages
turbo run build --filter=web     # Build specific app
turbo run dev --parallel         # Parallel dev servers
turbo run lint test --continue   # Continue on errors

# NX commands
nx run <project>:<target>        # Run target
nx affected --target=build       # Build affected only
nx graph                         # Visualize dependencies
```

---

## Workspace Structure

### Recommended Layout

```
monorepo/
├── apps/
│   ├── web/                 # Next.js web app
│   ├── mobile/              # Expo mobile app
│   └── api/                 # Backend service
├── packages/
│   ├── ui/                  # Shared UI components
│   ├── config/              # Shared configs (tsconfig, eslint)
│   ├── utils/               # Shared utilities
│   └── db/                  # Database schema & client
├── tooling/
│   ├── eslint/              # ESLint configs
│   ├── typescript/          # TypeScript configs
│   └── tailwind/            # Tailwind config
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

### pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "tooling/*"
```

### Root package.json

```json
{
  "name": "monorepo",
  "private": true,
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "test": "turbo test",
    "clean": "turbo clean && rm -rf node_modules",
    "format": "prettier --write \"**/*.{ts,tsx,md}\""
  },
  "devDependencies": {
    "turbo": "^2.0.0",
    "prettier": "^3.0.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

---

## Turborepo Configuration

### turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": ["coverage/**"]
    },
    "clean": {
      "cache": false
    }
  }
}
```

### Key Concepts

| Concept | Meaning |
|---------|---------|
| `^build` | Run build in dependencies first |
| `outputs` | Cached artifacts |
| `cache: false` | Never cache this task |
| `persistent: true` | Long-running task (dev servers) |
| `dependsOn` | Task dependencies |

---

## Internal Packages

### Package Structure

```
packages/ui/
├── src/
│   ├── index.ts          # Main exports
│   ├── button.tsx
│   └── card.tsx
├── package.json
└── tsconfig.json
```

### package.json for Internal Package

```json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts",
    "./button": "./src/button.tsx",
    "./card": "./src/card.tsx"
  },
  "scripts": {
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit"
  },
  "peerDependencies": {
    "react": "^18.0.0"
  },
  "devDependencies": {
    "@repo/typescript-config": "workspace:*",
    "@repo/eslint-config": "workspace:*",
    "typescript": "^5.0.0"
  }
}
```

### Using Internal Packages

```json
// apps/web/package.json
{
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/utils": "workspace:*"
  }
}
```

```typescript
// apps/web/app/page.tsx
import { Button } from "@repo/ui/button"
import { formatDate } from "@repo/utils"
```

---

## Shared Configuration

### TypeScript Config Package

```
packages/config/typescript/
├── base.json
├── nextjs.json
├── react-library.json
└── package.json
```

```json
// packages/config/typescript/base.json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noUncheckedIndexedAccess": true
  }
}
```

```json
// apps/web/tsconfig.json
{
  "extends": "@repo/typescript-config/nextjs.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

### ESLint Config Package

```javascript
// packages/config/eslint/next.js
module.exports = {
  extends: [
    "next/core-web-vitals",
    "./base.js"
  ],
  rules: {
    // Next.js specific rules
  }
}
```

---

## Development Workflow

### Running Development Servers

```bash
# All apps in parallel
turbo dev

# Specific app with dependencies
turbo dev --filter=web...

# Watch mode for packages
turbo dev --filter="./packages/*"
```

### Building

```bash
# Build everything (uses cache)
turbo build

# Build specific app with dependencies
turbo build --filter=web...

# Force rebuild (no cache)
turbo build --force
```

### Testing Changed Packages

```bash
# Test only changed packages
turbo test --filter="...[origin/main]"

# Lint changed packages
turbo lint --filter="...[origin/main]"
```

---

## Dependency Management

### Adding Dependencies

```bash
# Add to specific package
pnpm --filter web add react-query

# Add to root (dev dependencies)
pnpm -w add -D turbo

# Add workspace dependency
pnpm --filter web add @repo/ui@workspace:*
```

### Updating Dependencies

```bash
# Update all packages
pnpm update -r

# Update specific dependency everywhere
pnpm update -r typescript

# Interactive update
pnpm update -r -i
```

---

## CI/CD with Turborepo

### GitHub Actions

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2  # For turbo caching

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Lint
        run: pnpm lint

      - name: Test
        run: pnpm test
```

### Remote Caching

```bash
# Login to Vercel (for remote cache)
npx turbo login

# Link to remote cache
npx turbo link

# Or self-hosted
# turbo.json: { "remoteCache": { "enabled": true } }
```

---

## Common Patterns

### Shared Environment Variables

```typescript
// packages/env/index.ts
import { createEnv } from "@t3-oss/env-nextjs"
import { z } from "zod"

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    API_SECRET: z.string().min(1),
  },
  client: {
    NEXT_PUBLIC_API_URL: z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    API_SECRET: process.env.API_SECRET,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  },
})
```

### Database Package

```typescript
// packages/db/index.ts
export * from "./schema"
export * from "./client"

// packages/db/client.ts
import { drizzle } from "drizzle-orm/postgres-js"
import postgres from "postgres"
import * as schema from "./schema"

const client = postgres(process.env.DATABASE_URL!)
export const db = drizzle(client, { schema })
```

---

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Circular dependencies between packages | Clear dependency hierarchy |
| Copy-paste configs across apps | Shared config packages |
| Different versions of same dep | Single version in root |
| Build all on every change | Use turbo filtering |
| Manual dependency graph | Let turbo/nx manage it |
| node_modules in each package | pnpm's single node_modules |

---

## Troubleshooting

### Common Issues

```bash
# Clear all caches
turbo clean
pnpm store prune
rm -rf node_modules
pnpm install

# Debug turbo task graph
turbo build --dry-run

# Check why package was rebuilt
turbo build --summarize

# Visualize dependency graph
turbo run build --graph
```

### Package Resolution Issues

```bash
# Check why package is being used
pnpm why <package>

# Force reinstall
pnpm install --force

# Check for peer dependency issues
pnpm install --strict-peer-dependencies
```

---

## Migration Checklist

Converting to monorepo:

```markdown
## Monorepo Migration

### Setup
- [ ] Initialize pnpm workspace
- [ ] Configure turbo.json
- [ ] Set up shared configs (TS, ESLint)

### Extract Packages
- [ ] Identify shared code
- [ ] Create internal packages
- [ ] Update imports across apps

### CI/CD
- [ ] Update build pipeline
- [ ] Configure remote caching
- [ ] Set up affected-only testing

### Documentation
- [ ] Update README with workspace commands
- [ ] Document package dependencies
- [ ] Create contribution guidelines
```

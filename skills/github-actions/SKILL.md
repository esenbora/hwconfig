---
name: github-actions
description: GitHub Actions CI/CD patterns. Testing, linting, deployment workflows.
version: 1.0.0
detect: [".github/workflows"]
---

# GitHub Actions (2026)

> CI/CD automation patterns for modern web applications.

---

## Basic CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm test:ci
        env:
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

  build:
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm build
        env:
          NEXT_PUBLIC_API_URL: ${{ vars.NEXT_PUBLIC_API_URL }}
```

---

## E2E Testing with Playwright

```yaml
# .github/workflows/e2e.yml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile

      - name: Install Playwright Browsers
        run: pnpm exec playwright install --with-deps chromium

      - name: Run E2E tests
        run: pnpm test:e2e
        env:
          BASE_URL: http://localhost:3000
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7

      - name: Upload screenshots
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screenshots
          path: test-results/
          retention-days: 7
```

---

## Database Migrations

```yaml
# .github/workflows/migrate.yml
name: Database Migration

on:
  push:
    branches: [main]
    paths:
      - 'prisma/migrations/**'
      - 'drizzle/migrations/**'

jobs:
  migrate:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile

      - name: Run migrations
        run: pnpm db:migrate:deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## Deployment Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'preview'
        type: choice
        options:
          - preview
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'preview' }}

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: ${{ github.event.inputs.environment == 'production' && '--prod' || '' }}
```

---

## Security Scanning

```yaml
# .github/workflows/security.yml
name: Security

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  dependency-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=high

  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript, typescript

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3

  secrets-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

---

## Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate Changelog
        id: changelog
        uses: mikepenz/release-changelog-builder-action@v4
        with:
          configuration: '.github/changelog-config.json'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: ${{ contains(github.ref, 'alpha') || contains(github.ref, 'beta') }}
```

---

## Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      DATABASE_URL:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm test:ci
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

```yaml
# .github/workflows/main.yml - Using reusable workflow
name: Main

on: [push, pull_request]

jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
    secrets:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## Caching Strategies

```yaml
# Cache pnpm store
- uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      pnpm-store-

# Cache Next.js build
- uses: actions/cache@v4
  with:
    path: .next/cache
    key: nextjs-${{ hashFiles('**/pnpm-lock.yaml') }}-${{ hashFiles('**/*.ts', '**/*.tsx') }}
    restore-keys: |
      nextjs-${{ hashFiles('**/pnpm-lock.yaml') }}-

# Cache Playwright browsers
- uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-${{ hashFiles('**/pnpm-lock.yaml') }}
```

---

## Environment Protection

```yaml
# In workflow
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com

# Repository Settings > Environments > production
# - Required reviewers
# - Wait timer (e.g., 5 minutes)
# - Deployment branches (only main)
```

---

## Secrets Management

```yaml
# Organization secrets - shared across repos
# Repository secrets - specific to repo
# Environment secrets - specific to environment

# Access in workflow
env:
  API_KEY: ${{ secrets.API_KEY }}          # Secret
  API_URL: ${{ vars.API_URL }}             # Variable (non-sensitive)
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # Auto-provided
```

---

## Best Practices

```yaml
# 1. Use specific action versions
- uses: actions/checkout@v4  # ✅ Pinned major
- uses: actions/checkout@main  # ❌ Floating

# 2. Set timeouts
jobs:
  build:
    timeout-minutes: 15

# 3. Use concurrency to cancel stale runs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# 4. Fail fast for matrix builds
strategy:
  fail-fast: true
  matrix:
    node: [18, 20, 22]

# 5. Use job dependencies
jobs:
  test:
    needs: [lint, typecheck]
```

---

## Security Checklist

```
□ Secrets stored in GitHub Secrets (not in code)
□ GITHUB_TOKEN with minimal permissions
□ Environment protection for production
□ Required reviewers for production deploy
□ Dependabot enabled for security updates
□ CodeQL analysis enabled
□ Concurrency limits to prevent abuse
```

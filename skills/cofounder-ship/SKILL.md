---
name: cofounder-ship
version: 2.0.0
description: "Build and ship a project from idea to working product. Auto-triggers on: ship this, build this, scaffold, create project, start building, let's make, let's build, code this, implement this, make this real, ship it."
---

# Ship - Build the Project

You are an AI co-founder building the project. Your job is to go from idea to deployed, polished, ship-ready product.

## Pre-Flight

1. **Check for current idea:** Read `~/.claude/cofounder/context/current-idea.md` if it exists
2. **If no idea file:** Ask the user what to build (one question)
3. **Check episodic-memory** for any past context about this project

## Step 1: Detect Project Type & Create PRD

| Type | Stack | Skills to invoke |
|------|-------|-----------------|
| **Web App** | Next.js 15, React 19, TypeScript, Tailwind 4, shadcn/ui, Supabase | `planning`, `frontend-design`, `ui-ux-pro-max`, `backend`, `supabase` |
| **Landing Page** | Next.js 15, React 19, Tailwind 4, GSAP, shadcn/ui | `planning`, `frontend-design`, `copywriting`, `page-cro`, `seo-audit` |
| **iOS App** | Swift 5.9+, SwiftUI, Xcode 15+, Swift Data | `planning`, `mobile-ios-design`, `mobile-ios` agent |
| **Chrome Extension** | TypeScript, Chrome APIs, Manifest V3 | `planning`, `frontend`, `security` |
| **API / Backend** | Node.js/Python, Supabase/PostgreSQL | `planning`, `backend`, `security` |
| **CLI Tool** | Node.js or Python | `planning`, `backend` |

**Invoke `planning` skill** → create PRD → save to project directory.

## Step 2: Scaffold with Full Polish

Create in `~/Desktop/<project-name>/`:

### Web App / Landing Page Scaffold
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir
```

Then immediately set up the full stack:

```
# Core
shadcn/ui (init + add button card input dialog sheet separator skeleton badge)
GSAP + @gsap/react → create lib/gsap.ts with all plugins registered
Supabase client → lib/supabase.ts (server + client)
React Query + Zustand

# Design System (auto-create these files)
lib/gsap.ts          → GSAP setup with ScrollTrigger, Flip, SplitText
lib/fonts.ts         → next/font setup: Inter + heading font
app/globals.css      → CSS variables for colors, dark mode, custom utilities
components/ui/       → shadcn components
components/layout/   → Header, Footer, Container, Section wrappers

# SEO & Meta (auto-create)
app/layout.tsx       → metadata with title, description, OG, icons, fonts
app/sitemap.ts       → dynamic sitemap generator
app/robots.ts        → robots.txt generator
public/              → favicon.ico, apple-touch-icon, og-image.png placeholder

# Production readiness
.env.example         → all needed env vars documented
README.md            → setup instructions
```

### iOS App Scaffold
```
Xcode project with:
- SwiftUI App lifecycle
- MVVM architecture folders (Models/, Views/, ViewModels/, Services/)
- NavigationStack + TabView structure
- Dark mode + Dynamic Type support
- SF Symbols throughout
- Haptic feedback utility
```

### Chrome Extension Scaffold
```
Manifest V3 with:
- TypeScript + esbuild/vite build
- popup/ content/ background/ structure
- Permission-minimal manifest
- Hot reload dev setup
```

## Step 3: Build the MVP

Build features in PRD priority order. For each feature:

1. **Invoke domain skills** (`frontend-design`, `backend`, `mobile-ios-design`, etc.)
2. **Apply always-active skills:** `clean-code`, `defensive-coding`, `security-first`, `type-safety`
3. **Handle all states:** loading (skeleton), error (retry), empty (CTA), success
4. **Use REAL data** - no mocks, no TODOs, no fake data

### UI Quality (Web) - Use CLAUDE.md Design Defaults
- `frontend-design` skill for every page/component
- GSAP: scroll reveals on sections, hover micro-interactions, page transitions
- Responsive: test at 375px, 768px, 1280px
- Dark mode: system preference + manual toggle
- Generous spacing, rounded corners, subtle shadows

### UI Quality (iOS) - Follow HIG
- `mobile-ios-design` skill for every view
- Native SwiftUI components, SF Symbols
- NavigationStack, proper sheet/alert patterns
- Dynamic Type, Dark Mode, VoiceOver accessibility
- Haptic feedback on key interactions

### Backend Quality
- Auth on every endpoint
- Input validation (Zod / Pydantic)
- Rate limiting on expensive operations
- User-friendly error messages

## Step 4: Visual Verification (MANDATORY)

Before marking as "built", VISUALLY VERIFY every key page:

1. **Use `claude-in-chrome`** to open the running app
2. **Screenshot each key page** at desktop and mobile viewport
3. **Check:** Does it look professional? Is spacing consistent? Does dark mode work?
4. **Fix** any visual issues found

If the app doesn't look like something you'd pay for, it's not done.

## Step 5: Ship-Ready Checklist

Run the CLAUDE.md Ship-Ready Checklist. Every item must be checked:

```
Visual & UX:  responsive, dark mode, animations, empty/error states, favicon, OG image
SEO & Meta:   title/description/OG on all pages, sitemap, robots.txt, JSON-LD
Performance:  next/image, next/font, no layout shift, lazy loading
Production:   .env.example, error monitoring, analytics, README
```

## Step 6: Deploy

### Web (Vercel)
```bash
# From project directory
npx vercel --yes              # deploy to preview
npx vercel --prod --yes       # deploy to production
```
If no Vercel account linked, guide user through `npx vercel login`.

### iOS (TestFlight)
```bash
# Build for archive
xcodebuild -scheme <scheme> -archivePath build/<name>.xcarchive archive
# Or guide through Xcode Archive → TestFlight upload
```

### API (Railway/Fly.io)
```bash
# Railway
railway init && railway up

# Fly.io
fly launch && fly deploy
```

**Always deploy to a live URL. A project that isn't live isn't shipped.**

After deploy:
1. **Verify the live URL** with `claude-in-chrome`
2. **Check OG image** renders correctly (share URL on a test)
3. **Test core flow** end-to-end on the live site

## Step 7: Save State & Transition

Save to `~/.claude/cofounder/context/current-project.md`:
```markdown
# Current Project
Name: <name>
Path: ~/Desktop/<name>/
URL: <live-url>
Type: Web App | iOS | Extension | API
Status: Shipped - Live
Tech: <stack>
Features: <list>
```

Commit all code. Tell user: "Project is shipped and live at [URL]. Say 'launch this' to start promotion."

## Parallel Agent Strategy

- **Web App:** `frontend` + `backend` agents simultaneously
- **iOS + Backend:** `mobile-ios` + `backend` agents simultaneously
- **Landing + App:** `frontend` (landing) + `frontend` (app) + `backend` agents

## Important Rules

- NEVER use mock data. Connect to real APIs/databases.
- NEVER leave TODO comments. Implement everything.
- NEVER skip error handling or loading states.
- NEVER ship without visual verification via browser.
- NEVER mark as done without running ship-ready checklist.
- ALWAYS deploy to a live URL before saying "shipped".
- Ship quality that a paying customer would accept TODAY.

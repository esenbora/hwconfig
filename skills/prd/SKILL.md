---
name: prd
description: Use when planning a new project or feature. Product requirements document generation. Triggers on: prd, product requirements, plan project, requirements document, spec, specification, project plan.
argument-hint: "<product-or-feature-idea>"
version: 1.0.0
context: fork
agent: architect
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
---


## WORKFLOW OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRD GENERATION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PHASE 1: DISCOVERY                                             │
│  └─> What are we building? Why? For whom?                       │
│                                                                 │
│  PHASE 2: USERS & PROBLEM                                       │
│  └─> Deep dive into target users and their pain points          │
│                                                                 │
│  PHASE 3: MARKET & COMPETITION                                  │
│  └─> Who else solves this? How do we differentiate?             │
│                                                                 │
│  PHASE 4: FEATURES & SCOPE                                      │
│  └─> What exactly will we build? (MoSCoW prioritization)        │
│                                                                 │
│  PHASE 5: SUCCESS METRICS                                       │
│  └─> How do we measure success?                                 │
│                                                                 │
│  PHASE 6: TECH STACK                                            │
│  └─> Now we know WHAT, choose HOW (framework, DB, etc.)         │
│                                                                 │
│  PHASE 7: ARCHITECTURE                                          │
│  └─> System design based on chosen stack                        │
│                                                                 │
│  PHASE 8: DATA MODEL                                            │
│  └─> Database schema, relationships, indexes                    │
│                                                                 │
│  PHASE 9: UI/UX DESIGN                                          │
│  └─> Design direction, pages, user flows                        │
│                                                                 │
│  PHASE 10: SECURITY & COMPLIANCE                                │
│  └─> Security requirements, legal, OWASP                        │
│                                                                 │
│  PHASE 11: IMPLEMENTATION PLAN                                  │
│  └─> Sprints, risks, timeline                                   │
│                                                                 │
│  OUTPUT: docs/PRD.md + prd.json                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## PHASE 0: KNOWLEDGE CHECK

**Before starting, silently check:**

```
1. Read .claude/DONT_DO.md - Any failed approaches to avoid?
2. Read .claude/CRITICAL_NOTES.md - Any existing patterns?
3. Read progress.txt - Any context from previous work?
4. Check package.json - Is this an existing project?
```

If **existing project**, also analyze:
- Current tech stack
- Existing patterns (src/ structure)
- Database schema (if exists)

---

## PHASE 1: DISCOVERY

**Use AskUserQuestion tool to gather:**

### 1.1 Project Identity

```yaml
Questions:
  - header: "Name"
    question: "What is this product/feature called?"
    options:
      - label: "[User provides name]"
        description: "The official name for this project"

  - header: "Pitch"
    question: "Describe it in one sentence (elevator pitch)"
    options:
      - label: "[User provides pitch]"
        description: "One sentence that captures the essence"

  - header: "Type"
    question: "What type of project is this?"
    options:
      - label: "New Product"
        description: "Building from scratch"
      - label: "Major Feature"
        description: "Adding to existing product"
      - label: "MVP/Prototype"
        description: "Quick validation"
      - label: "Migration/Rebuild"
        description: "Rebuilding existing system"
```

### 1.2 Business Context

```yaml
Questions:
  - header: "Context"
    question: "Is this for a client, personal project, or startup?"
    options:
      - label: "Client Work"
        description: "Building for someone else"
      - label: "Personal/Side Project"
        description: "Your own project"
      - label: "Startup"
        description: "Building a business"
      - label: "Internal Tool"
        description: "For your company/team"

  - header: "Timeline"
    question: "Is there a deadline?"
    options:
      - label: "Yes, hard deadline"
        description: "Must launch by specific date"
      - label: "Yes, soft deadline"
        description: "Target date but flexible"
      - label: "No deadline"
        description: "Ship when ready"

  - header: "Team"
    question: "Team size?"
    options:
      - label: "Solo"
        description: "Just you"
      - label: "Small (2-5)"
        description: "Small team"
      - label: "Medium (5-15)"
        description: "Growing team"
      - label: "Large (15+)"
        description: "Large organization"
```

**Wait for answers before proceeding.**

---

## PHASE 2: USERS & PROBLEM

### 2.1 User Type

```yaml
Questions:
  - header: "User Type"
    question: "Who is your primary user?"
    options:
      - label: "B2C - Consumers"
        description: "General public, individuals"
      - label: "B2B - Businesses"
        description: "Companies as customers"
      - label: "B2B2C - Platform"
        description: "Businesses serve their customers through you"
      - label: "Internal Users"
        description: "Employees, internal teams"
      - label: "Developers"
        description: "Technical users, API consumers"
```

### 2.2 User Research Questions

**Ask these open-ended questions:**

```
1. Who is the primary user? (age, role, tech-savviness)
2. What problem do they have TODAY?
3. How do they solve it CURRENTLY? (competitors, manual process, workarounds)
4. What would make them SWITCH to your solution?
5. How will they DISCOVER your product?
```

### 2.3 Problem Definition

```yaml
Questions:
  - header: "Problem"
    question: "What specific problem are you solving?"
    # Open text response

  - header: "Severity"
    question: "How painful is this problem?"
    options:
      - label: "Critical"
        description: "Users are desperate for a solution"
      - label: "High"
        description: "Significant pain, actively looking"
      - label: "Medium"
        description: "Annoying but manageable"
      - label: "Low"
        description: "Nice to solve, not urgent"

  - header: "Frequency"
    question: "How often do users face this problem?"
    options:
      - label: "Daily"
        description: "Every day use case"
      - label: "Weekly"
        description: "Regular occurrence"
      - label: "Monthly"
        description: "Periodic need"
      - label: "Occasionally"
        description: "Rare but important"
```

### 2.4 Generate User Personas

Based on answers, generate 2-3 personas:

```markdown
## Persona: [Name]
- **Role:** [Job/situation]
- **Age:** [Range]
- **Tech Level:** [Low/Medium/High]
- **Goal:** [What they want to achieve]
- **Pain Points:** [Current frustrations]
- **Quote:** "[What they might say]"
```

**Wait for user approval of personas.**

---

## PHASE 3: MARKET & COMPETITION

### 3.1 Competitor Research

**Use WebSearch to find competitors, then ask:**

```yaml
Questions:
  - header: "Competitors"
    question: "Who are your main competitors? (I'll research them)"
    # Open text - list competitor names

  - header: "Why Different"
    question: "Why will users choose YOU over competitors?"
    options:
      - label: "Better UX"
        description: "Easier to use, better design"
      - label: "Better Price"
        description: "Cheaper or better value"
      - label: "Better Features"
        description: "Capabilities others lack"
      - label: "Better for Niche"
        description: "Specialized for specific audience"
      - label: "First Mover"
        description: "No real competitors yet"
```

### 3.2 Competitive Analysis Table

Generate after research:

```markdown
| Competitor | Strengths | Weaknesses | Pricing | Our Advantage |
|------------|-----------|------------|---------|---------------|
| [Name] | | | | |
```

### 3.3 Differentiation Strategy

```
1. What MUST we match from competitors? (table stakes)
2. What can we do BETTER? (improvement opportunity)
3. What can we do that NO ONE else does? (unique value)
4. What's our UNFAIR ADVANTAGE? (moat)
```

**Wait for user input.**

---

## PHASE 4: FEATURES & SCOPE

### 4.1 Feature Brainstorm

**Ask user to list ALL potential features:**

```yaml
Questions:
  - header: "Features"
    question: "List all features you're considering (we'll prioritize next)"
    # Open text - bullet list of features
```

### 4.2 MoSCoW Prioritization

**For each feature, use AskUserQuestion with multiSelect:**

```yaml
Questions:
  - header: "Must Have"
    question: "Which features are MUST HAVE for MVP? (Can't launch without)"
    multiSelect: true
    options:
      - label: "[Feature 1]"
        description: "[Brief description]"
      - label: "[Feature 2]"
        description: "[Brief description]"
      # ... generated from brainstorm

  - header: "Should Have"
    question: "Which features SHOULD HAVE for v1.1? (Important but not blocking)"
    multiSelect: true
    # ... remaining features

  - header: "Could Have"
    question: "Which features COULD HAVE if time permits?"
    multiSelect: true
    # ... remaining features
```

### 4.3 User Stories for Must-Have Features

Generate for each must-have:

```markdown
| Feature | User Story | Acceptance Criteria |
|---------|------------|---------------------|
| [Name] | As a [user], I want [goal] so that [reason] | - Criterion 1<br>- Criterion 2<br>- TypeScript passes |
```

**Confirm user stories with user.**

---

## PHASE 5: SUCCESS METRICS

### 5.1 Business Metrics

```yaml
Questions:
  - header: "Revenue"
    question: "What's your revenue target?"
    options:
      - label: "No revenue (free product)"
        description: "Not monetizing"
      - label: "Side income ($100-1K/mo)"
        description: "Hobby level"
      - label: "Sustainable ($1K-10K/mo)"
        description: "Can support itself"
      - label: "Business ($10K+/mo)"
        description: "Real business"

  - header: "Users"
    question: "User target for first 3 months?"
    options:
      - label: "< 100"
        description: "Early validation"
      - label: "100-1,000"
        description: "Early traction"
      - label: "1,000-10,000"
        description: "Growing"
      - label: "10,000+"
        description: "Scale"

  - header: "Monetization"
    question: "How will you monetize?"
    options:
      - label: "Subscription (SaaS)"
        description: "Monthly/yearly payments"
      - label: "One-time purchase"
        description: "Pay once"
      - label: "Freemium"
        description: "Free tier + paid features"
      - label: "Usage-based"
        description: "Pay per use"
      - label: "Free (no monetization)"
        description: "Not charging users"
```

### 5.2 Product Metrics

```yaml
Questions:
  - header: "Core Action"
    question: "What is THE ONE action users must complete?"
    # Open text - the key value action

  - header: "Retention"
    question: "How often should users return?"
    options:
      - label: "Daily"
        description: "Daily active use expected"
      - label: "Weekly"
        description: "Weekly check-ins"
      - label: "Monthly"
        description: "Monthly use case"
      - label: "As needed"
        description: "Event-driven usage"
```

### 5.3 Define KPIs

Based on answers, define:

```markdown
## Success Metrics

### Business KPIs
- Revenue: $___/month by month ___
- Users: ___ users by month ___
- Conversion: ___% free to paid

### Product KPIs
- DAU/MAU ratio: ___%
- Core action completion: ___%
- Day 7 retention: ___%
- Day 30 retention: ___%

### Technical KPIs
- Page load (LCP): < ___s
- API response (p95): < ___ms
- Uptime: ___% (99.9% = 8.76h downtime/year)
- Error rate: < ___%
```

**Confirm metrics with user.**

---

## PHASE 6: TECH STACK

**NOW we know what we're building. Choose the right tools.**

### 6.1 Platform

```yaml
Questions:
  - header: "Platform"
    question: "What platform(s) are you targeting?"
    multiSelect: true
    options:
      - label: "Web (Desktop + Mobile)"
        description: "Browser-based application"
      - label: "iOS Native"
        description: "Native iPhone/iPad app"
      - label: "Android Native"
        description: "Native Android app"
      - label: "Cross-platform Mobile"
        description: "React Native, Flutter, etc."
      - label: "Desktop App"
        description: "Electron, Tauri, etc."
```

### 6.2 Frontend (if Web)

```yaml
Questions:
  - header: "Frontend"
    question: "Frontend framework preference?"
    options:
      - label: "Next.js (Recommended)"
        description: "Full-stack React, SSR/SSG, best ecosystem"
      - label: "Remix"
        description: "Great forms, progressive enhancement"
      - label: "Vite + React"
        description: "Simple SPA, fast dev"
      - label: "Astro"
        description: "Content-first, minimal JS"
      - label: "No preference"
        description: "Let me recommend based on requirements"
```

### 6.3 Styling

```yaml
Questions:
  - header: "Styling"
    question: "Styling approach?"
    options:
      - label: "Tailwind + shadcn/ui (Recommended)"
        description: "Rapid development, accessible components"
      - label: "Tailwind + Radix"
        description: "More control, build your own system"
      - label: "CSS Modules"
        description: "Traditional, isolated styles"
      - label: "Styled Components"
        description: "CSS-in-JS"
```

### 6.4 Database

```yaml
Questions:
  - header: "Database"
    question: "Database preference?"
    options:
      - label: "PostgreSQL + Supabase (Recommended)"
        description: "Real-time, auth included, generous free tier"
      - label: "PostgreSQL + Neon"
        description: "Serverless, branching, scale to zero"
      - label: "PostgreSQL + Railway"
        description: "Simple, traditional hosting"
      - label: "MongoDB Atlas"
        description: "Flexible schema, document model"
      - label: "No preference"
        description: "Let me recommend based on data model"
```

### 6.5 ORM

```yaml
Questions:
  - header: "ORM"
    question: "ORM preference?"
    options:
      - label: "Prisma (Recommended)"
        description: "Best DX, type safety, migrations, studio"
      - label: "Drizzle"
        description: "Performance, SQL-like, lighter"
      - label: "Raw SQL"
        description: "Direct queries, full control"
```

### 6.6 Authentication

```yaml
Questions:
  - header: "Auth"
    question: "Authentication approach?"
    options:
      - label: "Clerk (Recommended for speed)"
        description: "Quick setup, beautiful UI, MFA - $25/mo after 10k MAU"
      - label: "NextAuth/Auth.js"
        description: "Flexible, free, many providers - more setup"
      - label: "Supabase Auth"
        description: "If using Supabase - integrated"
      - label: "Lucia"
        description: "Full control, learning opportunity"
      - label: "Kinde"
        description: "B2B features, organizations"
```

### 6.7 Hosting

```yaml
Questions:
  - header: "Hosting"
    question: "Hosting preference?"
    options:
      - label: "Vercel (Recommended for Next.js)"
        description: "Best DX, edge functions - cost at scale"
      - label: "Cloudflare Pages"
        description: "Edge, cost-effective - some Next.js limits"
      - label: "Railway"
        description: "Full-stack, Docker - less edge"
      - label: "Fly.io"
        description: "Global, containers - more DevOps"
```

### 6.8 Additional Services

```yaml
Questions:
  - header: "Services"
    question: "Which additional services do you need?"
    multiSelect: true
    options:
      - label: "Payments (Stripe/Lemon Squeezy)"
        description: "Accept payments"
      - label: "Email (Resend/SendGrid)"
        description: "Transactional emails"
      - label: "File Storage (UploadThing/R2)"
        description: "User uploads"
      - label: "Real-time (Pusher/Ably)"
        description: "Live updates, WebSockets"
      - label: "AI/LLM (OpenAI/Claude)"
        description: "AI features"
      - label: "Search (Algolia/Meilisearch)"
        description: "Full-text search"
      - label: "Background Jobs (Inngest/Trigger.dev)"
        description: "Async processing"
      - label: "Analytics (PostHog/Mixpanel)"
        description: "User analytics"
      - label: "Error Tracking (Sentry)"
        description: "Error monitoring"
```

### 6.9 Final Stack Summary

Generate summary table:

```markdown
## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Frontend | Next.js 14 | SSR, API routes, best ecosystem |
| Styling | Tailwind + shadcn | Rapid dev, accessible |
| Database | PostgreSQL (Supabase) | Real-time, auth, free tier |
| ORM | Prisma | Type safety, migrations |
| Auth | Clerk | Quick setup, MFA |
| Hosting | Vercel | Best Next.js support |
| Payments | Stripe | Industry standard |
| Email | Resend | Modern, React Email |
```

**Confirm stack with user before proceeding.**

---

## PHASE 7: ARCHITECTURE

### 7.1 System Architecture Diagram

Generate based on chosen stack:

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
│              Browser │ Mobile │ API Consumers                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        CDN / EDGE                                │
│                   Vercel Edge Network                           │
│              Static Assets │ Edge Functions                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION                                 │
│                    Next.js App Router                           │
├─────────────────────────────────────────────────────────────────┤
│  Pages (RSC)  │  API Routes  │  Server Actions  │  Middleware   │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │   DATABASE   │  │    CACHE     │  │   STORAGE    │
    │  PostgreSQL  │  │    Redis     │  │   R2/S3      │
    │  (Supabase)  │  │  (Upstash)   │  │              │
    └──────────────┘  └──────────────┘  └──────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                             │
│   Auth (Clerk) │ Payments (Stripe) │ Email (Resend) │ AI       │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Folder Structure

```
project/
├── app/                      # Next.js App Router
│   ├── (marketing)/          # Public pages (landing, pricing)
│   │   ├── page.tsx
│   │   ├── pricing/
│   │   └── blog/
│   ├── (auth)/               # Auth pages
│   │   ├── sign-in/[[...sign-in]]/
│   │   └── sign-up/[[...sign-up]]/
│   ├── (dashboard)/          # Protected app pages
│   │   ├── layout.tsx        # Dashboard layout with sidebar
│   │   ├── page.tsx          # Dashboard home
│   │   ├── settings/
│   │   └── [feature]/        # Feature-specific pages
│   ├── api/                  # API routes
│   │   ├── webhooks/         # Webhook handlers
│   │   └── [...]/            # Other API endpoints
│   ├── layout.tsx            # Root layout
│   └── globals.css
├── components/
│   ├── ui/                   # shadcn/ui components
│   ├── forms/                # Form components
│   ├── layouts/              # Layout components (header, sidebar)
│   └── [feature]/            # Feature-specific components
├── lib/
│   ├── db/                   # Database (Prisma client, queries)
│   ├── auth/                 # Auth utilities
│   ├── validations/          # Zod schemas
│   └── utils/                # Utility functions
├── server/
│   ├── actions/              # Server actions
│   └── services/             # Business logic services
├── hooks/                    # Custom React hooks
├── types/                    # TypeScript types
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── public/                   # Static assets
└── config/                   # App configuration
```

### 7.3 Key Architectural Decisions

```yaml
Questions:
  - header: "API Style"
    question: "How should frontend communicate with backend?"
    options:
      - label: "Server Actions (Recommended)"
        description: "Direct mutations, type-safe, simpler"
      - label: "API Routes"
        description: "REST-like, external access possible"
      - label: "tRPC"
        description: "End-to-end type safety, RPC style"

  - header: "State Management"
    question: "Client-side state management?"
    options:
      - label: "React Query + Zustand (Recommended)"
        description: "Server state + client state separated"
      - label: "React Query only"
        description: "Mostly server state"
      - label: "Zustand only"
        description: "Simple client state"
      - label: "Redux Toolkit"
        description: "Complex state, time-travel debugging"
```

**Document architecture decisions in CRITICAL_NOTES.md**

---

## PHASE 8: DATA MODEL

### 8.1 Core Entities

**Ask about main data objects:**

```yaml
Questions:
  - header: "Entities"
    question: "What are the main objects in your system?"
    # Open text - list entities (User, Post, Order, etc.)
```

### 8.2 Generate Schema

Based on entities, generate Prisma schema:

```prisma
// Example schema - customize based on answers

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  posts     Post[]

  @@index([email])
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String

  @@index([authorId])
  @@index([published])
}

enum Role {
  USER
  ADMIN
}
```

### 8.3 Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐
│     User     │       │     Post     │
├──────────────┤       ├──────────────┤
│ id           │──────<│ id           │
│ email        │       │ title        │
│ name         │       │ content      │
│ role         │       │ published    │
│ createdAt    │       │ authorId     │
│ updatedAt    │       │ createdAt    │
└──────────────┘       │ updatedAt    │
                       └──────────────┘
```

**Review schema with user.**

---

## PHASE 9: UI/UX DESIGN

### 9.1 Design Direction

```yaml
Questions:
  - header: "Design Style"
    question: "What design aesthetic fits your brand?"
    options:
      - label: "Minimal Modern"
        description: "Clean, lots of whitespace, subtle shadows"
      - label: "Neo-Brutalism"
        description: "Bold borders, raw shapes, playful"
      - label: "Editorial/Magazine"
        description: "Large serif headlines, content-first"
      - label: "Dark & Technical"
        description: "Developer-focused, terminal vibes"
      - label: "Warm & Friendly"
        description: "Soft colors, rounded corners, approachable"
      - label: "No preference"
        description: "Let me suggest based on audience"
```

### 9.2 Color Mode

```yaml
Questions:
  - header: "Color Mode"
    question: "Primary color mode?"
    options:
      - label: "Light mode (toggle available)"
        description: "White background default"
      - label: "Dark mode (toggle available)"
        description: "Dark background default"
      - label: "System preference"
        description: "Auto-switch based on OS"
```

### 9.3 Pages Needed

```yaml
Questions:
  - header: "Pages"
    question: "Which pages do you need?"
    multiSelect: true
    options:
      - label: "Landing Page"
        description: "Marketing homepage"
      - label: "Pricing Page"
        description: "Plan comparison"
      - label: "Blog/Changelog"
        description: "Content pages"
      - label: "Documentation"
        description: "Help/docs pages"
      - label: "Dashboard"
        description: "Main app interface"
      - label: "Settings"
        description: "User preferences"
      - label: "Profile"
        description: "User profile page"
      - label: "Billing"
        description: "Subscription management"
```

### 9.4 User Flows

Document critical journeys:

```markdown
## User Flows

### 1. Onboarding Flow
Landing → Sign Up → [Onboarding Steps] → Dashboard

### 2. Core Action Flow
Dashboard → [Feature] → [Action] → Success

### 3. Upgrade Flow
Free User → Pricing → Checkout → Paid Features

### 4. Recovery Flows
- Forgot Password → Email → Reset → Login
- Error → Error Page → Support/Retry
```

### 9.5 Accessibility Checklist

```markdown
## Accessibility (WCAG 2.2 AA)

NON-NEGOTIABLE:
- [ ] Focus indicators: 2px outline, 3:1 contrast
- [ ] Touch targets: minimum 24px (44px recommended)
- [ ] Color contrast: 4.5:1 for text, 3:1 for UI
- [ ] Keyboard navigation: Tab, Enter, Escape work
- [ ] Screen reader: ARIA labels, live regions
- [ ] Motion: respect prefers-reduced-motion
- [ ] Font size: base 16px minimum
```

---

## PHASE 10: SECURITY & COMPLIANCE

### 10.1 Security Requirements

```yaml
Questions:
  - header: "Security Level"
    question: "What level of security is required?"
    options:
      - label: "Standard (Recommended minimum)"
        description: "HTTPS, auth, input validation, OWASP basics"
      - label: "Enhanced"
        description: "MFA, audit logs, encryption at rest"
      - label: "Enterprise"
        description: "SOC 2, penetration testing, compliance"
      - label: "Regulated"
        description: "HIPAA, PCI DSS, special requirements"
```

### 10.2 OWASP API Security Top 10 2023

```markdown
## Security Checklist (MANDATORY)

Every endpoint MUST address:
- [ ] API1 - BOLA: Ownership validation on every resource
- [ ] API2 - Broken Auth: Rate limiting, bcrypt 12+, MFA option
- [ ] API3 - Property Auth: Explicit field allowlists
- [ ] API4 - Resource Consumption: Rate/size limits, pagination
- [ ] API5 - BFLA: Function-level permission checks
- [ ] API6 - Business Flow: Anti-automation for sensitive ops
- [ ] API7 - SSRF: URL validation, private IP blocking
- [ ] API8 - Misconfiguration: Security headers, debug off
- [ ] API9 - Inventory: API versioning strategy
- [ ] API10 - Unsafe Consumption: External API validation
```

### 10.3 Compliance

```yaml
Questions:
  - header: "Compliance"
    question: "Which compliance requirements apply?"
    multiSelect: true
    options:
      - label: "GDPR (EU users)"
        description: "Cookie consent, data export, deletion rights"
      - label: "CCPA (California)"
        description: "Privacy notice, opt-out"
      - label: "SOC 2 (Enterprise sales)"
        description: "Security controls certification"
      - label: "HIPAA (Healthcare)"
        description: "PHI protection"
      - label: "PCI DSS (Payments)"
        description: "Card data handling"
      - label: "None specifically"
        description: "No special requirements"
```

### 10.4 Legal Pages

```markdown
## Required Legal Pages

- [ ] Privacy Policy
- [ ] Terms of Service
- [ ] Cookie Policy (if EU users)
- [ ] Acceptable Use Policy (if UGC)
- [ ] DPA (if B2B with EU customers)
```

---

## PHASE 11: IMPLEMENTATION PLAN

### 11.1 Sprint Breakdown

```markdown
## Sprint 1: Foundation (Week 1-2)
- [ ] Project setup (Next.js, TypeScript, Tailwind, shadcn)
- [ ] Database setup + initial schema
- [ ] Authentication setup (Clerk/NextAuth)
- [ ] Base layout components
- [ ] CI/CD pipeline (GitHub Actions → Vercel)
- [ ] Development environment documentation

## Sprint 2: Core Features (Week 3-4)
- [ ] [Must-Have Feature 1]
- [ ] [Must-Have Feature 2]
- [ ] [Must-Have Feature 3]

## Sprint 3: Polish (Week 5)
- [ ] Error handling & error boundaries
- [ ] Loading states (skeletons)
- [ ] Edge cases & validation
- [ ] Mobile responsiveness
- [ ] Accessibility audit

## Sprint 4: Launch Prep (Week 6)
- [ ] Testing (unit, integration, e2e)
- [ ] Performance optimization
- [ ] Security audit
- [ ] Marketing pages
- [ ] Documentation
- [ ] Launch checklist
```

### 11.2 Risk Assessment

```markdown
## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Technical complexity | M | H | Spike early, POC for unknowns |
| Scope creep | H | H | Strict MoSCoW, defer "nice to have" |
| Third-party dependency | L | M | Abstract interfaces, have backup |
| Security vulnerability | M | H | Security audit before launch |
| Performance issues | M | M | Load test, monitoring from day 1 |
```

### 11.3 Dependencies & Blockers

```markdown
## External Dependencies

- [ ] Domain name secured?
- [ ] Third-party API access (keys, accounts)?
- [ ] Design assets ready?
- [ ] Content/copy written?
- [ ] Legal review complete?
```

---

## PHASE 12: OUTPUT

### 12.1 Generate PRD Document

**Save to: `docs/PRD.md`**

```markdown
# [Product Name] - Product Requirements Document

**Version:** 1.0
**Created:** [Date]
**Author:** [Name]
**Status:** Draft

---

## Executive Summary

[One paragraph overview]

## Problem Statement

[What problem, why it matters, who has it]

## Target Users

[User types, personas, jobs to be done]

## Success Metrics

[Business KPIs, Product KPIs, Technical KPIs]

## Competitive Analysis

[Competitors, differentiation, positioning]

## Features (Prioritized)

### Must Have (MVP)
[Feature list with user stories]

### Should Have (v1.1)
[Feature list]

### Could Have (Future)
[Feature list]

## Tech Stack

[Chosen technologies with rationale]

## Architecture

[System diagram, folder structure, key decisions]

## Data Model

[Schema, relationships, indexes]

## UI/UX Direction

[Design style, color mode, key pages, user flows]

## Security & Compliance

[Requirements, OWASP checklist, legal pages]

## Implementation Plan

[Sprints, risks, dependencies]

## Open Questions

[Anything still TBD]

---

*Generated with Claude Code PRD Generator*
```

### 12.2 Ready for Implementation

PRD is complete. Now use `/start-todo` to execute:

```bash
/start-todo docs/PRD.md   # Convert PRD to tasks and start TDD execution
```

---

## NEXT STEPS

After PRD completion:

```markdown
1. **Review & Approve PRD**
   - Share with stakeholders
   - Get sign-off on scope

2. **Start Implementation**
   → /start-todo docs/PRD.md   # Parse PRD, generate tasks, execute with TDD
   → /start-todo resume        # Continue where you left off

3. **Update Knowledge Files**
   → /knowledge critical   # Architecture decisions
   → /knowledge progress   # Log PRD creation
```

---

## REMEMBER

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "Give me six hours to chop down a tree and I will spend      │
│    the first four sharpening the axe." - Abraham Lincoln       │
│                                                                 │
│   A comprehensive PRD saves WEEKS of development time.          │
│   Take the time to get it right.                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## MOBILE PLATFORM

When generating a PRD for React Native / Expo mobile apps, include these additional phases.

### Mobile-Specific Skills & Agents

```yaml
Skills:
  Load for Mobile:
    - react-native-deep       # RN architecture
    - expo-deep               # Expo specifics

Agents:
  Lead: mobile-orchestrator   # Coordinates PRD creation
  Consult:
    - architect               # System design
    - mobile-rn               # React Native patterns
    - mobile-ui               # Mobile UX
    - mobile-integration      # Push, payments, analytics
    - mobile-release          # Store requirements
    - security                # Mobile security
```

### Platform Strategy Questions

#### 1. Platform Choice
- A. Cross-platform (React Native/Expo) - *Recommended for most apps*
- B. Cross-platform (Flutter)
- C. iOS only (Swift/SwiftUI)
- D. Android only (Kotlin/Compose)
- E. Both native (separate codebases)

#### 2. Development Approach (if React Native)
- A. Expo managed - Quick start, OTA updates, limited native
- B. Expo bare - Native modules + Expo tools
- C. React Native CLI - Full native control

#### 3. Target Platforms
- A. iPhone only
- B. iPhone + iPad (universal)
- C. Android phones only
- D. Android phones + tablets
- E. All of the above

### Device Features Questions

#### Required Device Features (select all needed)
- A. Camera (photos, video, scanning)
- B. GPS/Location
- C. Push notifications
- D. Biometrics (Face ID, Touch ID, Fingerprint)
- E. Offline mode with sync
- F. Background processing
- G. Deep linking / Universal links
- H. Payments (in-app purchases, subscriptions)
- I. None of the above

#### Minimum OS Support
- iOS: 15 / 16 / 17 / Latest only?
- Android: API 24 (7.0) / API 26 (8.0) / API 29 (10)?

### Offline & Sync Questions

#### Offline Requirements
- A. No offline support needed
- B. Read-only offline (cache data)
- C. Full offline with sync (create/edit offline)
- D. Offline-first (primary mode)

#### Sync Strategy (if offline)
- A. Last-write-wins (simple)
- B. Server-side conflict resolution
- C. Client-side conflict resolution
- D. Full CRDT (collaborative)

### Mobile Tech Stack Recommendations

#### Navigation
| Choice | Best For |
|--------|----------|
| Expo Router | File-based, Expo apps |
| React Navigation | Flexible, mature |
| React Native Navigation | Native performance |

#### State Management
| Choice | Best For |
|--------|----------|
| TanStack Query | Server state, caching |
| Zustand | Client state, simple |
| Jotai | Atomic state |
| Redux Toolkit | Complex shared state |

#### Local Storage
| Choice | Best For |
|--------|----------|
| MMKV | Fast key-value (recommended) |
| SecureStore | Sensitive data (tokens) |
| WatermelonDB | Offline-first, complex |
| SQLite | Complex queries |

#### UI/Styling
| Choice | Best For |
|--------|----------|
| NativeWind | Tailwind developers |
| Tamagui | Cross-platform, fast |
| React Native Paper | Material Design |
| Gluestack | Accessible |

### Mobile UI/UX Questions

#### Design System
- A. iOS-first (Human Interface Guidelines)
- B. Android-first (Material Design 3)
- C. Custom cross-platform (same UI everywhere)
- D. Platform-adaptive (native feel each platform)

#### Navigation Pattern
- A. Tab bar (bottom tabs)
- B. Drawer (side menu)
- C. Stack only (simple)
- D. Combination

### Mobile Security Questions

#### Security Level
- A. Standard (HTTPS, token auth)
- B. Enhanced (biometrics, secure storage)
- C. High (certificate pinning, jailbreak detection)
- D. Maximum (all above + additional hardening)

### App Store Strategy Questions

#### Release Strategy
- A. App Store + Play Store (public)
- B. TestFlight + Internal Testing only
- C. Enterprise distribution (no public stores)
- D. Start internal, then public

#### Monetization
- A. Free
- B. Paid app
- C. Freemium (in-app purchases)
- D. Subscription
- E. Ads

### Mobile Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     App Architecture                         │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Screens (Expo Router)                                  ││
│  │  ├── (tabs)/ - Tab navigation                          ││
│  │  ├── (auth)/ - Authentication screens                  ││
│  │  └── (modals)/ - Modal screens                         ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  State Layer                                            ││
│  │  ├── Server State (TanStack Query)                     ││
│  │  ├── Client State (Zustand)                            ││
│  │  └── Local Storage (MMKV + SecureStore)                ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  API Layer                                              ││
│  │  └── API Client -> Backend                              ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Mobile Performance Targets

- Cold start: < 2 seconds
- 60fps animations (no drops)
- Bundle size: < 50MB
- Memory: Stable, no leaks

### Mobile Platform Guidelines

- [ ] iOS Human Interface Guidelines compliance
- [ ] Android Material Design compliance
- [ ] App Store Review Guidelines
- [ ] Play Store policies

### Mobile PRD Document Structure

Save PRD to: `docs/MOBILE-PRD.md`

```markdown
# [App Name] - Mobile PRD

## 1. Executive Summary
## 2. Platform Strategy
   - Platform: [Choice + rationale]
   - Min OS: [Versions]
## 3. Target Users & Scale
## 4. Tech Stack
   - Navigation: [Choice]
   - State: [Choice]
   - Storage: [Choice]
   - UI: [Choice]
## 5. Architecture Diagram
## 6. Feature List (Prioritized)
   - MVP Features
   - Phase 2 Features
## 7. UI/UX Direction
   - Design system
   - Navigation pattern
## 8. Mobile-Specific Requirements
   - Offline strategy
   - Device features
   - Security level
## 9. Implementation Plan
   - Phase 1: [Scope]
   - Phase 2: [Scope]
## 10. App Store Strategy
   - Release approach
   - Monetization
## 11. Security Requirements
## 12. Performance Targets
## 13. Risks & Mitigations
```

### Next Steps for Mobile

After PRD approval:
1. **For autonomous:** `/auto convert docs/MOBILE-PRD.md`
2. **For manual:** `/m-feature [first-feature]`

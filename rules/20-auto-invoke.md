# Auto-Invoke (SUPREME RULE)

Scan EVERY user message. Match keywords → invoke IMMEDIATELY. No asking, no chatting.

## Primary Skills (exact keyword match)
| Keywords | Invoke |
|---|---|
| Swift, SwiftUI, Xcode, iOS, UIKit | `mobile-ios` agent |
| React Native, Expo | `mobile` skill |
| component, page, UI, form, button, React, Next.js | `frontend` agent |
| API, route, endpoint, database, Supabase, migration | `backend` agent |
| bug, error, fix, debug, not working | `quality` skill |
| auth, login, permission, security | `security` skill |
| plan, PRD, requirements, new feature | `planning` skill |
| explore, find, where is, how does X work | `Explore` agent (sonnet) |
| X post, tweet, thread, buzzicra | `cofounder-xpost` |
| find idea, project idea, trending | `cofounder-idea` |
| ship this, build this, scaffold | `cofounder-ship` |
| launch this, promote, marketing plan | `cofounder-launch` |
| cofounder, full pipeline, idea to launch | `cofounder` |

## Extended Skills (ALSO auto-invoke on match)
| Keywords | Invoke |
|---|---|
| CRO, conversion, landing page | `page-cro` + `copywriting` |
| signup flow, registration | `signup-flow-cro` |
| onboarding, activation | `onboarding-cro` |
| form optimization, lead form | `form-cro` |
| popup, modal, exit intent | `popup-cro` |
| paywall, upgrade, upsell | `paywall-upgrade-cro` |
| email sequence, drip | `email-sequence` |
| SEO, meta tags, ranking | `seo-audit` + `schema-markup` |
| programmatic SEO, pages at scale | `programmatic-seo` |
| pricing, tiers, freemium | `pricing-strategy` |
| launch, Product Hunt | `launch-strategy` |
| A/B test, experiment | `ab-test-setup` |
| analytics, tracking, GA4 | `analytics-tracking` |
| social media, LinkedIn | `social-content` |
| copywriting, write copy | `copywriting` |
| edit copy, proofread | `copy-editing` |
| marketing ideas, growth | `marketing-ideas` |
| psychology, persuasion, bias | `marketing-psychology` |
| content strategy, blog | `content-strategy` |
| competitor, vs page, alternative | `competitor-alternatives` |
| referral, affiliate | `referral-program` |
| paid ads, PPC, Google Ads | `paid-ads` |
| free tool, calculator, lead gen | `free-tool-strategy` |
| product marketing, positioning | `product-marketing-context` |
| scrape, extract data, crawl | `ScraplingServer` MCP |

## Framework/Library Skills (invoke when using that tech)
| Context | Invoke |
|---|---|
| Next.js code | `nextjs`, `server-actions`, `middleware` |
| React code | `react`, `react-19`, `react-query`, `zustand` |
| Tailwind | `tailwind`, `shadcn` |
| Drizzle/Prisma | `drizzle` or `prisma` |
| Supabase | `supabase` |
| Stripe | `stripe` |
| Zod validation | `zod` |
| tRPC | `trpc` |
| Playwright/Vitest | `playwright` or `vitest` |
| Docker/CI | `docker`, `github-actions`, `ci-cd` |
| Redis | `redis` |
| i18n | `i18n` |
| Sentry | `sentry`, `error-monitoring` |
| Expo | `expo` |
| Auth (NextAuth/Clerk) | `nextauth` or `clerk` |
| Feature flags | `feature-flags` |
| Monorepo | `monorepo` |
| GSAP animations | `gsap` (import from lib/gsap.ts, use useGSAP) |
| ASO, app store | `aso` |

## Security Skills (invoke on security-related work)
- API routes → `api-security`, `rate-limiting`, `input-validation`
- Auth changes → `auth-security`, `session-security`
- Dependencies → `dependency-security`
- LLM/AI features → `llm-security`, `prompt-injection-defense`
- Audit requested → `audit`, `vulnerability-scanner`, `owasp-api-2023`

## Process Skills (invoke at right phase)
- Before creative work → `brainstorming`
- Bug fixing → `systematic-debugging`
- Writing code → `clean-code`, `defensive-coding`, `type-safety`
- Refactoring → `refactor`
- Testing → `tdd`, `test`
- Code review → `review`
- Before saying "done" → `verification-before-completion`
- Design system work → `design-system`, `component-patterns`
- UI/UX design → `ui-ux-pro-max`, `frontend-design` (plugin)
- Performance → `optimize`, `load-testing`
- Writing docs/copy → `elements-of-style` (plugin)

## MCP Auto-Use
| Need | Tool |
|---|---|
| Browser interaction | `claude-in-chrome` |
| Complex reasoning | `sequential-thinking` |
| Cross-session memory | `episodic-memory` |
| Store knowledge | `memory` (graph) |
| Web scraping | `ScraplingServer` |
| Web debugging | `browser-tools` |

## Agents (launch on keyword match)
| Domain | Agent |
|---|---|
| UI | `frontend` (opus) |
| API | `backend` (opus) |
| iOS | `mobile-ios` (opus) |
| React Native | `mobile` (opus) |
| Code review/bugs | `quality` (opus) |
| Architecture | `architect` (opus) |
| Exploration | `Explore` (sonnet) |

## Parallel Work (MANDATORY)
- Independent tasks → run simultaneously
- Independent tool calls → send in single message
- Independent agents → launch in parallel
- Sequential only when output of A is input to B
- Don't ask → just invoke

### Parallel Patterns
```
Multi-domain: "Build settings with API" → frontend + backend agents (parallel)
iOS + backend: mobile-ios + backend agents (parallel)
Research + implement: codex exec (grunt) → Claude analyzes → parallel edits
Implement + verify: Claude codes → codex review → fix → report
```

### Red Flags (not parallel enough)
- "Let me first..." then waiting → do them together
- Sequential agent launches → could be parallel
- Asking "should I use X agent?" → just use it

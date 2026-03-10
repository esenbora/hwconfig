# Claude Code

## Anti-Laziness
- No mock/fake data, no TODO comments, no empty handlers, no `any` types
- Handle ALL states: loading, error, empty, success
- Show user feedback on errors (not console.log)
- Done = works with real data, tsc clean, would ship today

## Code Patterns
API: auth() → validate(Schema) → ownership check → execute with try/catch
UI: loading → error → empty → data (handle ALL states)
Form: validation + loading state + user feedback

## Tech Stack
- **Web:** Next.js 15+, React 19, TypeScript strict, Tailwind 4, shadcn/ui, Supabase/Drizzle
- **Mobile:** Expo SDK 54+ / iOS Native: Swift 5.9+, SwiftUI
- **Animations:** GSAP (import from lib/gsap.ts, use useGSAP in React)

## Ship-Ready Checklist (ENFORCED before any project is "done")

### Visual & UX
- [ ] Responsive: mobile (375px), tablet (768px), desktop (1280px+)
- [ ] Dark mode support (system preference + toggle)
- [ ] Loading animations (skeleton/spinner, not blank screens)
- [ ] Page transitions & micro-interactions (GSAP)
- [ ] Empty states with illustration or CTA (not "no data")
- [ ] Error states with retry action (not raw error text)
- [ ] Favicon + app icon set
- [ ] OG image (1200x630) for social sharing
- [ ] Visual verification: screenshot every key page via browser tool

### SEO & Meta
- [ ] Title, description, OG tags on every page
- [ ] Sitemap.xml + robots.txt
- [ ] Canonical URLs
- [ ] Structured data (JSON-LD) for main content

### Performance
- [ ] Images: next/image with proper sizes, WebP/AVIF
- [ ] Fonts: next/font with display swap
- [ ] No layout shift (CLS < 0.1)
- [ ] Lazy load below-fold content

### Production
- [ ] Environment variables properly configured (.env.example)
- [ ] Error monitoring ready (Sentry or equivalent)
- [ ] Analytics snippet (Plausible/GA4/PostHog)
- [ ] Legal: privacy policy link, cookie notice if needed
- [ ] README with setup instructions + screenshots

### Deploy
- [ ] Deployed to live URL (Vercel/App Store/Railway)
- [ ] Custom domain or clean subdomain
- [ ] SSL/HTTPS working
- [ ] Build passes in CI (no warnings)

## Design Defaults (when no specific design is requested)

### Web Projects
- **Font:** Inter (body) + Cal Sans or Instrument Serif (headings) via next/font
- **Radius:** rounded-xl default, rounded-2xl for cards
- **Spacing:** generous - py-20+ sections, gap-6+ between elements
- **Colors:** neutral base (zinc/slate), one accent color, high contrast text
- **Shadows:** shadow-sm for cards, shadow-lg on hover (subtle elevation)
- **Animations:** GSAP scroll reveals (y:40, opacity:0, stagger), hover scales
- **Layout:** max-w-6xl centered, sidebar for dashboards, full-width hero for landing

### iOS Projects
- **Follow HIG strictly** - native components, SF Symbols, system colors
- **Typography:** SF Pro via Dynamic Type
- **Navigation:** NavigationStack, tab bar for 3-5 sections
- **Haptics:** on key interactions (success, error, selection)

### Landing Pages
- **Hero:** full-viewport, bold headline, one clear CTA, background gradient or mesh
- **Social proof:** logos, testimonials, or stats above fold
- **Sections:** feature grid, how-it-works, pricing, FAQ, final CTA
- **GSAP:** parallax hero, staggered feature reveals, counter animations

## NEVER
- Edit `.env` files
- Use `any` type
- Skip auth on API routes
- Ship mock data or TODO comments
- Say "done" without evidence
- Force push without asking
- Ship without running the ship-ready checklist

## Browser Automation
Ask user for help after first iframe/click failure. Don't retry blindly.

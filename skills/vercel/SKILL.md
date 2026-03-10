---
name: vercel
description: Vercel deployment, configuration, and features. Triggers on: vercel.json or .vercel folder.
version: 1.0.0
detect: ["vercel.json", ".vercel"]
---

# Vercel

Platform for deploying Next.js applications.

## Configuration

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm ci",
  "framework": "nextjs",
  "regions": ["iad1"],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    },
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/sitemap.xml", "destination": "/api/sitemap" }
  ],
  "redirects": [
    { "source": "/old-page", "destination": "/new-page", "permanent": true }
  ]
}
```

## Environment Variables

```bash
# Local development
# .env.local (git-ignored)
DATABASE_URL=postgres://...
CLERK_SECRET_KEY=sk_test_...

# Vercel Dashboard
# Settings > Environment Variables
# - Production
# - Preview
# - Development

# Access in code
process.env.DATABASE_URL
process.env.NEXT_PUBLIC_APP_URL  # Client-accessible (NEXT_PUBLIC_ prefix)
```

## Edge Functions

```typescript
// app/api/edge/route.ts
export const runtime = 'edge'

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const country = request.headers.get('x-vercel-ip-country')
  
  return Response.json({
    country,
    message: `Hello from the edge!`,
  })
}
```

## Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Geo-based routing
  const country = request.geo?.country || 'US'
  
  // A/B testing
  const bucket = request.cookies.get('bucket')?.value || 
    (Math.random() < 0.5 ? 'a' : 'b')
  
  const response = NextResponse.next()
  
  if (!request.cookies.has('bucket')) {
    response.cookies.set('bucket', bucket)
  }
  
  return response
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

## Caching

```typescript
// API Route caching
export async function GET() {
  const data = await fetchData()
  
  return Response.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  })
}

// Next.js data cache
async function getData() {
  const res = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }, // Revalidate every hour
  })
  return res.json()
}

// On-demand revalidation
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache'

export async function POST(request: Request) {
  const { path, tag } = await request.json()
  
  if (path) {
    revalidatePath(path)
  }
  if (tag) {
    revalidateTag(tag)
  }
  
  return Response.json({ revalidated: true })
}
```

## Analytics & Speed Insights

```tsx
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
```

## Cron Jobs

```typescript
// vercel.json
{
  "crons": [
    {
      "path": "/api/cron/daily-cleanup",
      "schedule": "0 0 * * *"
    }
  ]
}

// app/api/cron/daily-cleanup/route.ts
export async function GET(request: Request) {
  // Verify cron secret
  const authHeader = request.headers.get('authorization')
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  // Run cleanup
  await cleanupOldData()
  
  return Response.json({ success: true })
}
```

## Preview Deployments

```bash
# Every push to a branch creates a preview
# https://project-git-branch-team.vercel.app

# Comment on PRs with preview URL
# Automatic via Vercel GitHub integration
```

## CLI Commands

```bash
# Deploy
vercel

# Deploy to production
vercel --prod

# Pull env vars
vercel env pull .env.local

# Link project
vercel link

# View logs
vercel logs

# List deployments
vercel ls
```

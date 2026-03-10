---
name: nextjs
description: Use when building with Next.js. App Router, Server Components, data fetching, caching, layouts. Triggers on: next, nextjs, next.js, app router, server component, rsc, layout, page, loading, error, api route, server action.
version: 1.0.0
---

# Next.js Deep Knowledge

> App Router internals, caching strategies, ISR, and performance optimization.

---

## Quick Reference

```typescript
// Server Component (default)
export default async function Page() {
  const data = await fetchData();
  return <div>{data}</div>;
}

// Client Component
'use client';
export default function Button() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

---

## Caching Deep Dive

### Four Caching Layers

```
┌─────────────────────────────────────────────────────────────┐
│  1. Request Memoization (React)                              │
│     Same request in single render → cached                   │
├─────────────────────────────────────────────────────────────┤
│  2. Data Cache (fetch)                                       │
│     Persists across requests, deployments                    │
├─────────────────────────────────────────────────────────────┤
│  3. Full Route Cache (static pages)                          │
│     Pre-rendered at build time                               │
├─────────────────────────────────────────────────────────────┤
│  4. Router Cache (client-side)                               │
│     RSC payload cached in browser                            │
└─────────────────────────────────────────────────────────────┘
```

### Fetch Caching Options

```typescript
// Cache forever (default for GET)
fetch('https://api.example.com/data');

// No cache - always fresh
fetch('https://api.example.com/data', { cache: 'no-store' });

// Revalidate every 60 seconds
fetch('https://api.example.com/data', { next: { revalidate: 60 } });

// Revalidate on demand with tag
fetch('https://api.example.com/data', { next: { tags: ['posts'] } });
```

### Route Segment Config

```typescript
// Force dynamic rendering
export const dynamic = 'force-dynamic';

// Force static rendering
export const dynamic = 'force-static';

// Set revalidation time
export const revalidate = 60; // seconds

// Runtime selection
export const runtime = 'edge'; // or 'nodejs'

// Max duration for serverless
export const maxDuration = 30; // seconds
```

---

## Revalidation Strategies

### Time-Based (ISR)

```typescript
// Page revalidates every 60 seconds
export const revalidate = 60;

export default async function Page() {
  const data = await fetch('https://api.example.com/posts', {
    next: { revalidate: 60 },
  });
  return <PostList posts={data} />;
}
```

### On-Demand Revalidation

```typescript
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(request: Request) {
  const { path, tag, secret } = await request.json();
  
  // Verify secret
  if (secret !== process.env.REVALIDATION_SECRET) {
    return Response.json({ error: 'Invalid secret' }, { status: 401 });
  }
  
  if (tag) {
    // Revalidate all fetches with this tag
    revalidateTag(tag);
  }
  
  if (path) {
    // Revalidate specific path
    revalidatePath(path);
    // Or with type
    revalidatePath(path, 'page'); // or 'layout'
  }
  
  return Response.json({ revalidated: true, now: Date.now() });
}
```

### Revalidation in Server Actions

```typescript
'use server';

import { revalidatePath, revalidateTag } from 'next/cache';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  
  // Create post in database
  await db.post.create({ data: { title } });
  
  // Revalidate the posts page
  revalidatePath('/posts');
  
  // Or revalidate by tag
  revalidateTag('posts');
}
```

---

## Server Actions Deep Dive

### Form Actions

```typescript
// Direct form action
export default function Page() {
  async function createPost(formData: FormData) {
    'use server';
    const title = formData.get('title');
    await db.post.create({ data: { title } });
    revalidatePath('/posts');
  }
  
  return (
    <form action={createPost}>
      <input name="title" />
      <button type="submit">Create</button>
    </form>
  );
}
```

### With useActionState (React 19)

```typescript
'use client';

import { useActionState } from 'react';
import { createPost } from './actions';

export function CreatePostForm() {
  const [state, formAction, pending] = useActionState(createPost, null);
  
  return (
    <form action={formAction}>
      <input name="title" />
      <button type="submit" disabled={pending}>
        {pending ? 'Creating...' : 'Create'}
      </button>
      {state?.error && <p className="text-red-500">{state.error}</p>}
      {state?.success && <p className="text-green-500">Created!</p>}
    </form>
  );
}
```

### Progressive Enhancement

```typescript
'use client';

import { useOptimistic, useTransition } from 'react';
import { addTodo } from './actions';

export function TodoList({ todos }) {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newTodo) => [...state, { ...newTodo, pending: true }]
  );
  const [isPending, startTransition] = useTransition();
  
  async function handleSubmit(formData: FormData) {
    const title = formData.get('title');
    
    startTransition(async () => {
      // Immediately show optimistic update
      addOptimisticTodo({ id: Date.now(), title, pending: true });
      // Actually create the todo
      await addTodo(formData);
    });
  }
  
  return (
    <>
      <form action={handleSubmit}>
        <input name="title" />
        <button>Add</button>
      </form>
      <ul>
        {optimisticTodos.map((todo) => (
          <li key={todo.id} className={todo.pending ? 'opacity-50' : ''}>
            {todo.title}
          </li>
        ))}
      </ul>
    </>
  );
}
```

---

## Streaming & Suspense

### Streaming with Loading UI

```typescript
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />;
}

// app/dashboard/page.tsx
export default async function Dashboard() {
  const data = await slowFetch(); // Will show loading.tsx while fetching
  return <DashboardContent data={data} />;
}
```

### Streaming Specific Components

```typescript
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      
      {/* These stream independently */}
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
      
      <Suspense fallback={<ChartSkeleton />}>
        <Chart />
      </Suspense>
      
      <Suspense fallback={<TableSkeleton />}>
        <DataTable />
      </Suspense>
    </div>
  );
}

// Each component fetches its own data
async function Stats() {
  const stats = await fetchStats();
  return <StatsDisplay data={stats} />;
}
```

### Nested Suspense Boundaries

```typescript
export default function Page() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <MainContent>
        <Suspense fallback={<SidebarSkeleton />}>
          <Sidebar />
        </Suspense>
        <Suspense fallback={<ContentSkeleton />}>
          <Content />
        </Suspense>
      </MainContent>
    </Suspense>
  );
}
```

---

## Parallel & Sequential Data Fetching

### Parallel Fetching (Preferred)

```typescript
export default async function Page() {
  // Start all fetches simultaneously
  const userPromise = fetchUser();
  const postsPromise = fetchPosts();
  const statsPromise = fetchStats();
  
  // Wait for all
  const [user, posts, stats] = await Promise.all([
    userPromise,
    postsPromise,
    statsPromise,
  ]);
  
  return <Dashboard user={user} posts={posts} stats={stats} />;
}
```

### Sequential (When Needed)

```typescript
export default async function Page({ params }: { params: { id: string } }) {
  // First fetch user
  const user = await fetchUser(params.id);
  
  // Then fetch their posts (depends on user)
  const posts = await fetchPosts(user.id);
  
  return <UserProfile user={user} posts={posts} />;
}
```

### Preloading Data

```typescript
// utils/data.ts
import { cache } from 'react';

// Dedupe requests
export const getUser = cache(async (id: string) => {
  return await db.user.findUnique({ where: { id } });
});

// Preload function
export const preloadUser = (id: string) => {
  void getUser(id);
};

// layout.tsx
export default function Layout({ children, params }) {
  // Start fetching early
  preloadUser(params.id);
  return children;
}

// page.tsx
export default async function Page({ params }) {
  // Will use cached result
  const user = await getUser(params.id);
  return <Profile user={user} />;
}
```

---

## Route Handlers

### Request/Response Helpers

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  // Get query params
  const searchParams = request.nextUrl.searchParams;
  const query = searchParams.get('query');
  
  // Get headers
  const authHeader = request.headers.get('authorization');
  
  // Get cookies
  const token = request.cookies.get('token');
  
  const users = await db.user.findMany({ where: { name: { contains: query } } });
  
  return NextResponse.json(users, {
    status: 200,
    headers: {
      'Cache-Control': 'public, max-age=60',
    },
  });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  
  const user = await db.user.create({ data: body });
  
  return NextResponse.json(user, { status: 201 });
}
```

### Dynamic Route Params

```typescript
// app/api/users/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = await db.user.findUnique({ where: { id: params.id } });
  
  if (!user) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
  
  return NextResponse.json(user);
}
```

---

## Middleware Advanced

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();
  
  // Add headers
  response.headers.set('x-middleware-cache', 'no-cache');
  
  // Geolocation (Edge)
  const country = request.geo?.country || 'US';
  response.headers.set('x-country', country);
  
  // A/B Testing
  const bucket = request.cookies.get('ab-bucket')?.value || 
    Math.random() > 0.5 ? 'a' : 'b';
  
  if (!request.cookies.has('ab-bucket')) {
    response.cookies.set('ab-bucket', bucket, { maxAge: 60 * 60 * 24 * 30 });
  }
  
  // Rewrite for A/B
  if (request.nextUrl.pathname === '/pricing') {
    return NextResponse.rewrite(
      new URL(`/pricing/${bucket}`, request.url)
    );
  }
  
  // Redirect
  if (request.nextUrl.pathname === '/old-page') {
    return NextResponse.redirect(new URL('/new-page', request.url));
  }
  
  return response;
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

---

## Performance Optimization

### Image Optimization

```typescript
import Image from 'next/image';

// Local image
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority // Load immediately (above fold)
  placeholder="blur" // Show blur while loading
/>

// Remote image
<Image
  src="https://example.com/image.jpg"
  alt="Remote"
  width={400}
  height={300}
  loading="lazy" // Default
/>

// Fill container
<div className="relative w-full h-64">
  <Image
    src="/background.jpg"
    alt="Background"
    fill
    className="object-cover"
    sizes="100vw"
  />
</div>
```

### Script Optimization

```typescript
import Script from 'next/script';

// Analytics (after page is interactive)
<Script
  src="https://analytics.example.com/script.js"
  strategy="afterInteractive"
/>

// Third-party widget (lazy load)
<Script
  src="https://widget.example.com/widget.js"
  strategy="lazyOnload"
/>

// Critical script (blocking)
<Script
  src="/critical.js"
  strategy="beforeInteractive"
/>

// Inline script
<Script id="google-analytics">
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
  `}
</Script>
```

### Font Optimization

```typescript
// app/layout.tsx
import { Inter, Roboto_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

const robotoMono = Roboto_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-roboto-mono',
});

export default function RootLayout({ children }) {
  return (
    <html className={`${inter.variable} ${robotoMono.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
```

---

## Error Handling

### Error Boundary

```typescript
// app/dashboard/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

### Global Error

```typescript
// app/global-error.tsx
'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <h2>Something went wrong!</h2>
        <button onClick={() => reset()}>Try again</button>
      </body>
    </html>
  );
}
```

### Not Found

```typescript
// app/not-found.tsx
import Link from 'next/link';

export default function NotFound() {
  return (
    <div>
      <h2>Not Found</h2>
      <p>Could not find requested resource</p>
      <Link href="/">Return Home</Link>
    </div>
  );
}

// Trigger programmatically
import { notFound } from 'next/navigation';

export default async function Page({ params }) {
  const post = await fetchPost(params.id);
  
  if (!post) {
    notFound();
  }
  
  return <Post post={post} />;
}
```

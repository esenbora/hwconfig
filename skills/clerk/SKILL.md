---
name: clerk
description: Use when adding authentication with Clerk. User management, organizations, webhooks. Triggers on: clerk, clerk auth, sign in, sign up, user management, organization, clerk middleware, clerk webhook, currentUser, getAuth.
version: 1.0.0
---

# Clerk Deep Knowledge

> Webhooks, organizations, RBAC, and advanced auth patterns.

---

## Quick Reference

```typescript
import { auth, currentUser } from '@clerk/nextjs/server';

// Get auth info
const { userId } = auth();

// Get full user
const user = await currentUser();
```

---

## Middleware Configuration

### Complete Middleware

```typescript
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhooks(.*)',
  '/api/public(.*)',
]);

const isAdminRoute = createRouteMatcher(['/admin(.*)']);
const isApiRoute = createRouteMatcher(['/api(.*)']);

export default clerkMiddleware(async (auth, req) => {
  const { userId, sessionClaims, orgRole } = auth();
  
  // Public routes - no auth needed
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }
  
  // Protected routes - require auth
  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }
  
  // Admin routes - require admin role
  if (isAdminRoute(req)) {
    const role = sessionClaims?.metadata?.role;
    if (role !== 'admin') {
      return NextResponse.redirect(new URL('/unauthorized', req.url));
    }
  }
  
  return NextResponse.next();
});

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

---

## Webhooks

### Webhook Handler

```typescript
// app/api/webhooks/clerk/route.ts
import { Webhook } from 'svix';
import { headers } from 'next/headers';
import { WebhookEvent } from '@clerk/nextjs/server';
import { prisma } from '@/lib/prisma';

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;
  
  if (!WEBHOOK_SECRET) {
    throw new Error('Missing CLERK_WEBHOOK_SECRET');
  }
  
  // Get headers
  const headerPayload = headers();
  const svix_id = headerPayload.get('svix-id');
  const svix_timestamp = headerPayload.get('svix-timestamp');
  const svix_signature = headerPayload.get('svix-signature');
  
  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response('Missing svix headers', { status: 400 });
  }
  
  // Get body
  const payload = await req.json();
  const body = JSON.stringify(payload);
  
  // Verify webhook
  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;
  
  try {
    evt = wh.verify(body, {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature,
    }) as WebhookEvent;
  } catch (err) {
    console.error('Webhook verification failed:', err);
    return new Response('Invalid signature', { status: 400 });
  }
  
  // Handle events
  const eventType = evt.type;
  
  switch (eventType) {
    case 'user.created': {
      const { id, email_addresses, first_name, last_name, image_url } = evt.data;
      const primaryEmail = email_addresses[0]?.email_address;
      
      await prisma.user.create({
        data: {
          clerkId: id,
          email: primaryEmail,
          firstName: first_name,
          lastName: last_name,
          imageUrl: image_url,
        },
      });
      break;
    }
    
    case 'user.updated': {
      const { id, email_addresses, first_name, last_name, image_url } = evt.data;
      const primaryEmail = email_addresses[0]?.email_address;
      
      await prisma.user.update({
        where: { clerkId: id },
        data: {
          email: primaryEmail,
          firstName: first_name,
          lastName: last_name,
          imageUrl: image_url,
        },
      });
      break;
    }
    
    case 'user.deleted': {
      const { id } = evt.data;
      
      // Soft delete or cascade
      await prisma.user.update({
        where: { clerkId: id },
        data: { deletedAt: new Date() },
      });
      break;
    }
    
    case 'organization.created': {
      const { id, name, slug, created_by } = evt.data;
      
      await prisma.organization.create({
        data: {
          clerkOrgId: id,
          name,
          slug,
          createdById: created_by,
        },
      });
      break;
    }
    
    case 'organizationMembership.created': {
      const { organization, public_user_data, role } = evt.data;
      
      await prisma.orgMembership.create({
        data: {
          orgId: organization.id,
          userId: public_user_data.user_id,
          role,
        },
      });
      break;
    }
    
    default:
      console.log(`Unhandled webhook event: ${eventType}`);
  }
  
  return new Response('Webhook processed', { status: 200 });
}
```

---

## Organizations

### Organization Context

```typescript
// Get org context
import { auth } from '@clerk/nextjs/server';

export async function GET() {
  const { userId, orgId, orgRole, orgSlug } = auth();
  
  if (!orgId) {
    return new Response('No organization selected', { status: 400 });
  }
  
  // orgRole: 'org:admin' | 'org:member' | custom roles
  const isAdmin = orgRole === 'org:admin';
  
  return Response.json({ orgId, orgRole, isAdmin });
}
```

### Organization Switcher

```typescript
'use client';

import { OrganizationSwitcher } from '@clerk/nextjs';

export function OrgSwitcher() {
  return (
    <OrganizationSwitcher
      appearance={{
        elements: {
          rootBox: 'w-full',
          organizationSwitcherTrigger: 'w-full justify-between',
        },
      }}
      afterCreateOrganizationUrl="/org/:slug"
      afterSelectOrganizationUrl="/org/:slug"
      afterLeaveOrganizationUrl="/dashboard"
      createOrganizationMode="modal"
      organizationProfileMode="modal"
    />
  );
}
```

### Organization API

```typescript
import { clerkClient } from '@clerk/nextjs/server';

// List organization members
const members = await clerkClient.organizations.getOrganizationMembershipList({
  organizationId: orgId,
});

// Add member
await clerkClient.organizations.createOrganizationMembership({
  organizationId: orgId,
  userId: userId,
  role: 'org:member',
});

// Update member role
await clerkClient.organizations.updateOrganizationMembership({
  organizationId: orgId,
  userId: userId,
  role: 'org:admin',
});

// Remove member
await clerkClient.organizations.deleteOrganizationMembership({
  organizationId: orgId,
  userId: userId,
});

// Create invitation
await clerkClient.organizations.createOrganizationInvitation({
  organizationId: orgId,
  emailAddress: 'user@example.com',
  role: 'org:member',
  inviterUserId: currentUserId,
});
```

---

## Custom Roles & Permissions

### Define Roles (Clerk Dashboard)

```json
{
  "org:admin": {
    "name": "Admin",
    "permissions": [
      "org:settings:manage",
      "org:members:manage",
      "org:billing:manage"
    ]
  },
  "org:member": {
    "name": "Member",
    "permissions": [
      "org:content:read",
      "org:content:write"
    ]
  },
  "org:viewer": {
    "name": "Viewer",
    "permissions": [
      "org:content:read"
    ]
  }
}
```

### Check Permissions

```typescript
import { auth } from '@clerk/nextjs/server';

export async function DELETE(req: Request) {
  const { has, orgId } = auth();
  
  // Check specific permission
  if (!has({ permission: 'org:members:manage' })) {
    return new Response('Forbidden', { status: 403 });
  }
  
  // Check role
  if (!has({ role: 'org:admin' })) {
    return new Response('Admin required', { status: 403 });
  }
  
  // Proceed with deletion...
}
```

### Client-Side Permission Check

```typescript
'use client';

import { Protect, useAuth } from '@clerk/nextjs';

export function AdminPanel() {
  return (
    <Protect
      permission="org:settings:manage"
      fallback={<p>You don't have access to this section.</p>}
    >
      <AdminSettings />
    </Protect>
  );
}

// Or with hook
export function ConditionalUI() {
  const { has } = useAuth();
  
  const canManageMembers = has({ permission: 'org:members:manage' });
  
  return (
    <div>
      {canManageMembers && <ManageMembersButton />}
    </div>
  );
}
```

---

## User Metadata

### Public vs Private Metadata

```typescript
import { clerkClient } from '@clerk/nextjs/server';

// Public metadata (readable by frontend)
await clerkClient.users.updateUserMetadata(userId, {
  publicMetadata: {
    role: 'admin',
    tier: 'premium',
    onboardingComplete: true,
  },
});

// Private metadata (server-only)
await clerkClient.users.updateUserMetadata(userId, {
  privateMetadata: {
    stripeCustomerId: 'cus_xxx',
    internalNotes: 'VIP customer',
  },
});

// Unsafe metadata (user can edit)
// Set via UserProfile component or frontend SDK
```

### Access Metadata

```typescript
// Server
import { currentUser } from '@clerk/nextjs/server';

const user = await currentUser();
const role = user?.publicMetadata?.role;
const stripeId = user?.privateMetadata?.stripeCustomerId;

// Client
import { useUser } from '@clerk/nextjs';

function Component() {
  const { user } = useUser();
  const role = user?.publicMetadata?.role;
  // privateMetadata NOT accessible on client
}
```

### Session Claims

```typescript
// Include metadata in session token (no extra API calls)
// Configure in Clerk Dashboard -> Sessions -> Customize session token

// Access in middleware/server
const { sessionClaims } = auth();
const role = sessionClaims?.metadata?.role;
```

---

## Multi-Session Support

```typescript
'use client';

import { useSessionList, useSession } from '@clerk/nextjs';

export function SessionManager() {
  const { sessions, setActive } = useSessionList();
  const { session: currentSession } = useSession();
  
  return (
    <div>
      <h2>Active Sessions</h2>
      {sessions?.map((session) => (
        <div key={session.id}>
          <p>{session.user?.emailAddresses[0]?.emailAddress}</p>
          <p>Status: {session.status}</p>
          {session.id !== currentSession?.id && (
            <button onClick={() => setActive({ session: session.id })}>
              Switch to this session
            </button>
          )}
          <button onClick={() => session.end()}>
            Sign out of this session
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## Custom Sign-In Flow

```typescript
'use client';

import { useSignIn } from '@clerk/nextjs';
import { useState } from 'react';

export function CustomSignIn() {
  const { signIn, setActive, isLoaded } = useSignIn();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isLoaded) return;
    
    try {
      const result = await signIn.create({
        identifier: email,
        password,
      });
      
      if (result.status === 'complete') {
        await setActive({ session: result.createdSessionId });
        // Redirect to dashboard
      } else if (result.status === 'needs_second_factor') {
        // Handle 2FA
      }
    } catch (err: any) {
      setError(err.errors[0]?.message || 'Sign in failed');
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      {error && <p className="text-red-500">{error}</p>}
      <button type="submit">Sign In</button>
    </form>
  );
}
```

---

## Backend API (Server-Side)

```typescript
import { clerkClient } from '@clerk/nextjs/server';

// Get user
const user = await clerkClient.users.getUser(userId);

// List users
const users = await clerkClient.users.getUserList({
  limit: 100,
  orderBy: '-created_at',
  query: 'john',
});

// Create user
const newUser = await clerkClient.users.createUser({
  emailAddress: ['user@example.com'],
  password: 'secure-password',
  firstName: 'John',
  lastName: 'Doe',
});

// Delete user
await clerkClient.users.deleteUser(userId);

// Ban user
await clerkClient.users.banUser(userId);

// Unban user
await clerkClient.users.unbanUser(userId);
```

---

## Rate Limiting with Clerk

```typescript
import { auth } from '@clerk/nextjs/server';
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'),
});

export async function POST(req: Request) {
  const { userId } = auth();
  
  if (!userId) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const { success, remaining, reset } = await ratelimit.limit(userId);
  
  if (!success) {
    return new Response('Rate limit exceeded', {
      status: 429,
      headers: {
        'X-RateLimit-Remaining': remaining.toString(),
        'X-RateLimit-Reset': reset.toString(),
      },
    });
  }
  
  // Process request...
}
```

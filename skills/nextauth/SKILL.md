---
name: nextauth
description: NextAuth.js authentication patterns
version: 1.0.0
---

# NextAuth.js Deep Knowledge

> Custom providers, callbacks, sessions, and advanced auth patterns.

---

## Quick Reference

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import { authOptions } from '@/lib/auth';

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

---

## Auth Configuration

### Complete authOptions

```typescript
// lib/auth.ts
import { NextAuthOptions } from 'next-auth';
import { PrismaAdapter } from '@next-auth/prisma-adapter';
import GoogleProvider from 'next-auth/providers/google';
import CredentialsProvider from 'next-auth/providers/credentials';
import { prisma } from '@/lib/prisma';
import bcrypt from 'bcryptjs';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          prompt: 'consent',
          access_type: 'offline',
          response_type: 'code',
        },
      },
    }),
    
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error('Missing credentials');
        }
        
        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        });
        
        if (!user || !user.password) {
          throw new Error('Invalid credentials');
        }
        
        const isValid = await bcrypt.compare(credentials.password, user.password);
        
        if (!isValid) {
          throw new Error('Invalid credentials');
        }
        
        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        };
      },
    }),
  ],
  
  session: {
    strategy: 'jwt', // Use JWT for credentials provider
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
    verifyRequest: '/auth/verify-request',
    newUser: '/auth/new-user',
  },
  
  callbacks: {
    async signIn({ user, account, profile }) {
      // Custom sign-in logic
      if (account?.provider === 'google') {
        // Check if user is allowed
        const allowedDomains = ['company.com'];
        const email = user.email || '';
        const domain = email.split('@')[1];
        
        if (!allowedDomains.includes(domain)) {
          return false; // Reject sign-in
        }
      }
      return true;
    },
    
    async jwt({ token, user, account, trigger, session }) {
      // Add custom claims to JWT
      if (user) {
        token.id = user.id;
        token.role = user.role;
      }
      
      // Handle session update
      if (trigger === 'update' && session) {
        token.name = session.name;
      }
      
      return token;
    },
    
    async session({ session, token }) {
      // Add custom fields to session
      if (token) {
        session.user.id = token.id as string;
        session.user.role = token.role as string;
      }
      return session;
    },
    
    async redirect({ url, baseUrl }) {
      // Custom redirect logic
      if (url.startsWith('/')) return `${baseUrl}${url}`;
      if (new URL(url).origin === baseUrl) return url;
      return baseUrl;
    },
  },
  
  events: {
    async signIn({ user, account, isNewUser }) {
      if (isNewUser) {
        // Send welcome email
        await sendWelcomeEmail(user.email!);
      }
      // Log sign-in event
      await logAuthEvent('signIn', user.id);
    },
    
    async signOut({ token }) {
      await logAuthEvent('signOut', token.sub);
    },
    
    async createUser({ user }) {
      // Initialize user data
      await prisma.userSettings.create({
        data: { userId: user.id },
      });
    },
    
    async linkAccount({ user, account }) {
      // Account linked
    },
  },
  
  debug: process.env.NODE_ENV === 'development',
};
```

---

## Custom Providers

### OAuth Provider

```typescript
import type { OAuthConfig } from 'next-auth/providers';

interface CustomProfile {
  sub: string;
  email: string;
  name: string;
  picture?: string;
}

const CustomOAuthProvider: OAuthConfig<CustomProfile> = {
  id: 'custom-oauth',
  name: 'Custom OAuth',
  type: 'oauth',
  
  authorization: {
    url: 'https://provider.com/oauth/authorize',
    params: { scope: 'openid email profile' },
  },
  
  token: 'https://provider.com/oauth/token',
  userinfo: 'https://provider.com/oauth/userinfo',
  
  clientId: process.env.CUSTOM_CLIENT_ID,
  clientSecret: process.env.CUSTOM_CLIENT_SECRET,
  
  profile(profile) {
    return {
      id: profile.sub,
      email: profile.email,
      name: profile.name,
      image: profile.picture,
    };
  },
};
```

### Email Provider (Magic Links)

```typescript
import EmailProvider from 'next-auth/providers/email';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

EmailProvider({
  server: process.env.EMAIL_SERVER,
  from: process.env.EMAIL_FROM,
  
  async sendVerificationRequest({ identifier, url, provider }) {
    const { host } = new URL(url);
    
    await resend.emails.send({
      from: provider.from!,
      to: identifier,
      subject: `Sign in to ${host}`,
      html: `
        <body>
          <h1>Sign in to ${host}</h1>
          <p>Click the link below to sign in:</p>
          <a href="${url}">Sign in</a>
          <p>If you didn't request this, ignore this email.</p>
        </body>
      `,
    });
  },
  
  maxAge: 24 * 60 * 60, // 24 hours
}),
```

---

## Type Augmentation

```typescript
// types/next-auth.d.ts
import { DefaultSession, DefaultUser } from 'next-auth';
import { DefaultJWT } from 'next-auth/jwt';

declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      role: 'user' | 'admin';
    } & DefaultSession['user'];
  }
  
  interface User extends DefaultUser {
    role: 'user' | 'admin';
  }
}

declare module 'next-auth/jwt' {
  interface JWT extends DefaultJWT {
    id: string;
    role: 'user' | 'admin';
  }
}
```

---

## Session Handling

### Server Components

```typescript
// app/dashboard/page.tsx
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  
  if (!session) {
    redirect('/auth/signin');
  }
  
  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
      <p>Role: {session.user.role}</p>
    </div>
  );
}
```

### Server Actions

```typescript
'use server';

import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function updateProfile(formData: FormData) {
  const session = await getServerSession(authOptions);
  
  if (!session) {
    throw new Error('Unauthorized');
  }
  
  // Update profile...
}
```

### Client Components

```typescript
'use client';

import { useSession, signIn, signOut } from 'next-auth/react';

export function AuthButton() {
  const { data: session, status } = useSession();
  
  if (status === 'loading') {
    return <div>Loading...</div>;
  }
  
  if (session) {
    return (
      <div>
        <p>Signed in as {session.user.email}</p>
        <button onClick={() => signOut()}>Sign out</button>
      </div>
    );
  }
  
  return <button onClick={() => signIn()}>Sign in</button>;
}
```

### Update Session

```typescript
'use client';

import { useSession } from 'next-auth/react';

export function UpdateName() {
  const { update } = useSession();
  
  const handleUpdate = async () => {
    // Update session with new data
    await update({ name: 'New Name' });
  };
  
  return <button onClick={handleUpdate}>Update Name</button>;
}
```

---

## Middleware Protection

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware';
import { NextResponse } from 'next/server';

export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token;
    const pathname = req.nextUrl.pathname;
    
    // Admin routes require admin role
    if (pathname.startsWith('/admin') && token?.role !== 'admin') {
      return NextResponse.redirect(new URL('/unauthorized', req.url));
    }
    
    return NextResponse.next();
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
);

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*', '/api/protected/:path*'],
};
```

---

## Database Sessions (vs JWT)

### When to Use Database Sessions

```typescript
session: {
  strategy: 'database', // Use database sessions
  maxAge: 30 * 24 * 60 * 60,
  updateAge: 24 * 60 * 60, // Update session every 24h
}
```

| Strategy | Pros | Cons |
|----------|------|------|
| **JWT** | Stateless, no DB queries | Can't revoke, size limits |
| **Database** | Revokable, unlimited data | DB query per request |

### Revoke Sessions

```typescript
// Force sign out user (database sessions only)
await prisma.session.deleteMany({
  where: { userId: userId },
});
```

---

## Account Linking

```typescript
// Allow linking multiple providers to same account
callbacks: {
  async signIn({ user, account, profile }) {
    if (!user.email) return false;
    
    // Check if user exists with this email
    const existingUser = await prisma.user.findUnique({
      where: { email: user.email },
      include: { accounts: true },
    });
    
    if (existingUser) {
      // Check if this provider is already linked
      const isLinked = existingUser.accounts.some(
        (a) => a.provider === account?.provider
      );
      
      if (!isLinked && account) {
        // Link the account
        await prisma.account.create({
          data: {
            userId: existingUser.id,
            type: account.type,
            provider: account.provider,
            providerAccountId: account.providerAccountId,
            access_token: account.access_token,
            refresh_token: account.refresh_token,
            expires_at: account.expires_at,
          },
        });
      }
    }
    
    return true;
  },
}
```

---

## Error Handling

```typescript
// app/auth/error/page.tsx
'use client';

import { useSearchParams } from 'next/navigation';

const errors: Record<string, string> = {
  Configuration: 'Server configuration error',
  AccessDenied: 'Access denied',
  Verification: 'Verification link expired',
  Default: 'An error occurred',
};

export default function AuthError() {
  const searchParams = useSearchParams();
  const error = searchParams.get('error');
  
  return (
    <div>
      <h1>Authentication Error</h1>
      <p>{errors[error || 'Default']}</p>
    </div>
  );
}
```

---

## Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '1 m'), // 5 requests per minute
});

// In authorize callback
async authorize(credentials, req) {
  const ip = req.headers['x-forwarded-for'] || 'anonymous';
  const { success, remaining } = await ratelimit.limit(ip);
  
  if (!success) {
    throw new Error('Too many login attempts. Try again later.');
  }
  
  // Continue with authentication...
}
```

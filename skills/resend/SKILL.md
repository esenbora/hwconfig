---
name: resend
description: Use when sending emails. Transactional emails, templates, React Email, domains. Triggers on: resend, email, send email, transactional email, react email, email template.
version: 1.0.0
detect: ["resend"]
---

# Resend

Modern email API for developers.

## Setup

```typescript
// lib/resend.ts
import { Resend } from 'resend'

export const resend = new Resend(process.env.RESEND_API_KEY)
```

## Send Email

```typescript
import { resend } from '@/lib/resend'

// Simple email
await resend.emails.send({
  from: 'onboarding@yourdomain.com',
  to: 'user@example.com',
  subject: 'Welcome!',
  html: '<p>Welcome to our app!</p>',
})

// With React Email template
import { WelcomeEmail } from '@/emails/welcome'

await resend.emails.send({
  from: 'onboarding@yourdomain.com',
  to: 'user@example.com',
  subject: 'Welcome!',
  react: WelcomeEmail({ name: 'John' }),
})
```

## React Email Templates

```tsx
// emails/welcome.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Heading,
  Html,
  Link,
  Preview,
  Section,
  Text,
} from '@react-email/components'

interface WelcomeEmailProps {
  name: string
  actionUrl?: string
}

export function WelcomeEmail({ name, actionUrl }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Preview>Welcome to our platform</Preview>
      <Body style={main}>
        <Container style={container}>
          <Heading style={h1}>Welcome, {name}!</Heading>
          <Text style={text}>
            Thanks for signing up. We're excited to have you on board.
          </Text>
          {actionUrl && (
            <Section style={buttonContainer}>
              <Button style={button} href={actionUrl}>
                Get Started
              </Button>
            </Section>
          )}
          <Text style={footer}>
            If you didn't create an account, you can safely ignore this email.
          </Text>
        </Container>
      </Body>
    </Html>
  )
}

const main = {
  backgroundColor: '#f6f9fc',
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
}

const container = {
  backgroundColor: '#ffffff',
  margin: '0 auto',
  padding: '40px 20px',
  borderRadius: '8px',
}

const h1 = {
  color: '#1a1a1a',
  fontSize: '24px',
  fontWeight: '600',
  margin: '0 0 20px',
}

const text = {
  color: '#4a4a4a',
  fontSize: '16px',
  lineHeight: '24px',
  margin: '0 0 20px',
}

const buttonContainer = {
  textAlign: 'center' as const,
  margin: '30px 0',
}

const button = {
  backgroundColor: '#000000',
  borderRadius: '6px',
  color: '#ffffff',
  fontSize: '16px',
  fontWeight: '600',
  padding: '12px 24px',
  textDecoration: 'none',
}

const footer = {
  color: '#898989',
  fontSize: '14px',
  margin: '40px 0 0',
}

export default WelcomeEmail
```

## Common Templates

```tsx
// emails/password-reset.tsx
export function PasswordResetEmail({ resetUrl }: { resetUrl: string }) {
  return (
    <Html>
      <Head />
      <Preview>Reset your password</Preview>
      <Body style={main}>
        <Container style={container}>
          <Heading style={h1}>Reset Password</Heading>
          <Text style={text}>
            Click the button below to reset your password.
            This link expires in 1 hour.
          </Text>
          <Button style={button} href={resetUrl}>
            Reset Password
          </Button>
          <Text style={footer}>
            If you didn't request this, ignore this email.
          </Text>
        </Container>
      </Body>
    </Html>
  )
}

// emails/magic-link.tsx
export function MagicLinkEmail({ magicLink }: { magicLink: string }) {
  return (
    <Html>
      <Head />
      <Preview>Sign in to your account</Preview>
      <Body style={main}>
        <Container style={container}>
          <Heading style={h1}>Sign In</Heading>
          <Text style={text}>Click below to sign in. Link expires in 15 minutes.</Text>
          <Button style={button} href={magicLink}>
            Sign In
          </Button>
        </Container>
      </Body>
    </Html>
  )
}
```

## Server Action

```typescript
'use server'

import { resend } from '@/lib/resend'
import { WelcomeEmail } from '@/emails/welcome'

export async function sendWelcomeEmail(email: string, name: string) {
  try {
    const { data, error } = await resend.emails.send({
      from: 'App <noreply@yourdomain.com>',
      to: email,
      subject: 'Welcome to our app!',
      react: WelcomeEmail({ name }),
    })

    if (error) {
      console.error('Email error:', error)
      return { success: false, error: 'Failed to send email' }
    }

    return { success: true, id: data?.id }
  } catch (error) {
    console.error('Email error:', error)
    return { success: false, error: 'Failed to send email' }
  }
}
```

## Preview Emails

```bash
# Install React Email
npm install react-email @react-email/components -D

# Preview in browser
npx react-email dev
```

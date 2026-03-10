---
name: i18n
description: Use when adding multiple languages, translations, or localization. next-intl, i18next, locale detection. Triggers on: i18n, translation, localization, internationalization, locale, language, multi-language, translate, rtl.
version: 1.0.0
detect: ["next-intl", "i18next"]
---

# Internationalization (i18n)

Multi-language support with next-intl.

## Setup

```typescript
// i18n.ts
import { getRequestConfig } from 'next-intl/server'

export default getRequestConfig(async ({ locale }) => ({
  messages: (await import(`./messages/${locale}.json`)).default,
}))

// next.config.ts
import createNextIntlPlugin from 'next-intl/plugin'

const withNextIntl = createNextIntlPlugin()

export default withNextIntl({
  // Your config
})
```

## Messages

```json
// messages/en.json
{
  "common": {
    "loading": "Loading...",
    "error": "Something went wrong",
    "save": "Save",
    "cancel": "Cancel"
  },
  "auth": {
    "login": "Sign in",
    "logout": "Sign out",
    "welcome": "Welcome, {name}!"
  },
  "products": {
    "title": "Products",
    "count": "{count, plural, =0 {No products} =1 {1 product} other {# products}}",
    "price": "{price, number, ::currency/USD}"
  }
}

// messages/es.json
{
  "common": {
    "loading": "Cargando...",
    "error": "Algo salió mal",
    "save": "Guardar",
    "cancel": "Cancelar"
  },
  "auth": {
    "login": "Iniciar sesión",
    "logout": "Cerrar sesión",
    "welcome": "¡Bienvenido, {name}!"
  }
}
```

## Middleware

```typescript
// middleware.ts
import createMiddleware from 'next-intl/middleware'

export default createMiddleware({
  locales: ['en', 'es', 'fr', 'de'],
  defaultLocale: 'en',
  localePrefix: 'as-needed', // or 'always'
})

export const config = {
  matcher: ['/', '/(en|es|fr|de)/:path*'],
}
```

## App Structure

```
app/
├── [locale]/
│   ├── layout.tsx
│   ├── page.tsx
│   └── products/
│       └── page.tsx
└── ...
```

## Layout

```tsx
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from 'next-intl'
import { getMessages } from 'next-intl/server'

export default async function LocaleLayout({
  children,
  params: { locale },
}: {
  children: React.ReactNode
  params: { locale: string }
}) {
  const messages = await getMessages()

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  )
}
```

## Server Components

```tsx
// app/[locale]/page.tsx
import { useTranslations } from 'next-intl'

export default function Home() {
  const t = useTranslations('common')

  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('description')}</p>
    </div>
  )
}
```

## Client Components

```tsx
'use client'

import { useTranslations } from 'next-intl'

export function Greeting({ name }: { name: string }) {
  const t = useTranslations('auth')

  return <p>{t('welcome', { name })}</p>
}
```

## Formatting

```tsx
import { useTranslations, useFormatter } from 'next-intl'

function ProductCard({ product }: { product: Product }) {
  const t = useTranslations('products')
  const format = useFormatter()

  return (
    <div>
      <p>{t('price', { price: product.price })}</p>
      {/* Or using formatter */}
      <p>{format.number(product.price, { style: 'currency', currency: 'USD' })}</p>
      <p>{format.dateTime(product.createdAt, { dateStyle: 'medium' })}</p>
      <p>{format.relativeTime(product.createdAt)}</p>
    </div>
  )
}
```

## Pluralization

```tsx
import { useTranslations } from 'next-intl'

function ProductCount({ count }: { count: number }) {
  const t = useTranslations('products')

  // Uses ICU message format
  return <p>{t('count', { count })}</p>
  // 0 -> "No products"
  // 1 -> "1 product"
  // 5 -> "5 products"
}
```

## Language Switcher

```tsx
'use client'

import { useLocale } from 'next-intl'
import { usePathname, useRouter } from 'next-intl/client'

export function LanguageSwitcher() {
  const locale = useLocale()
  const router = useRouter()
  const pathname = usePathname()

  const languages = [
    { code: 'en', name: 'English' },
    { code: 'es', name: 'Español' },
    { code: 'fr', name: 'Français' },
  ]

  return (
    <select
      value={locale}
      onChange={(e) => router.replace(pathname, { locale: e.target.value })}
    >
      {languages.map((lang) => (
        <option key={lang.code} value={lang.code}>
          {lang.name}
        </option>
      ))}
    </select>
  )
}
```

## Static Params

```typescript
// app/[locale]/page.tsx
export function generateStaticParams() {
  return [{ locale: 'en' }, { locale: 'es' }, { locale: 'fr' }]
}
```

## Metadata

```typescript
import { getTranslations } from 'next-intl/server'

export async function generateMetadata({
  params: { locale },
}: {
  params: { locale: string }
}) {
  const t = await getTranslations({ locale, namespace: 'metadata' })

  return {
    title: t('title'),
    description: t('description'),
  }
}
```

---
name: seo
description: Use when optimizing for search engines. Metadata, structured data, sitemap. Triggers on: seo, metadata, search engine, sitemap, robots, structured data, opengraph, og.
version: 1.0.0
detect: ["next-sitemap"]
---

# SEO

Search Engine Optimization patterns for Next.js.

## Metadata API

```typescript
// app/layout.tsx - Global metadata
import type { Metadata } from 'next'

export const metadata: Metadata = {
  metadataBase: new URL('https://yoursite.com'),
  title: {
    default: 'Your Site',
    template: '%s | Your Site',
  },
  description: 'Your site description',
  keywords: ['keyword1', 'keyword2'],
  authors: [{ name: 'Your Name' }],
  creator: 'Your Name',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://yoursite.com',
    siteName: 'Your Site',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Your Site',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Your Site',
    description: 'Your site description',
    images: ['/og-image.png'],
    creator: '@yourhandle',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
}
```

## Dynamic Metadata

```typescript
// app/blog/[slug]/page.tsx
import type { Metadata, ResolvingMetadata } from 'next'

type Props = {
  params: { slug: string }
}

export async function generateMetadata(
  { params }: Props,
  parent: ResolvingMetadata
): Promise<Metadata> {
  const post = await getPost(params.slug)

  const previousImages = (await parent).openGraph?.images || []

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: 'article',
      publishedTime: post.createdAt,
      authors: [post.author.name],
      images: [post.image, ...previousImages],
    },
    twitter: {
      card: 'summary_large_image',
      title: post.title,
      description: post.excerpt,
      images: [post.image],
    },
  }
}
```

## Sitemap

```typescript
// app/sitemap.ts
import { MetadataRoute } from 'next'

export default async function sitemap(): MetadataRoute.Sitemap {
  const posts = await db.post.findMany({
    where: { published: true },
    select: { slug: true, updatedAt: true },
  })

  const postUrls = posts.map((post) => ({
    url: `https://yoursite.com/blog/${post.slug}`,
    lastModified: post.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }))

  return [
    {
      url: 'https://yoursite.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: 'https://yoursite.com/about',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.5,
    },
    ...postUrls,
  ]
}
```

## Robots.txt

```typescript
// app/robots.ts
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/', '/private/'],
      },
    ],
    sitemap: 'https://yoursite.com/sitemap.xml',
  }
}
```

## Structured Data (JSON-LD)

```typescript
// components/structured-data.tsx
export function ArticleJsonLd({ post }: { post: Post }) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post.title,
    description: post.excerpt,
    image: post.image,
    datePublished: post.createdAt,
    dateModified: post.updatedAt,
    author: {
      '@type': 'Person',
      name: post.author.name,
      url: `https://yoursite.com/author/${post.author.slug}`,
    },
    publisher: {
      '@type': 'Organization',
      name: 'Your Site',
      logo: {
        '@type': 'ImageObject',
        url: 'https://yoursite.com/logo.png',
      },
    },
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  )
}

// Organization
export function OrganizationJsonLd() {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'Your Company',
    url: 'https://yoursite.com',
    logo: 'https://yoursite.com/logo.png',
    sameAs: [
      'https://twitter.com/yourhandle',
      'https://github.com/yourhandle',
    ],
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  )
}

// Product
export function ProductJsonLd({ product }: { product: Product }) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: product.description,
    image: product.images,
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'USD',
      availability: 'https://schema.org/InStock',
    },
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  )
}
```

## Canonical URLs

```typescript
// In page metadata
export const metadata: Metadata = {
  alternates: {
    canonical: 'https://yoursite.com/blog/post-slug',
  },
}

// For paginated content
export async function generateMetadata({ searchParams }) {
  const page = searchParams.page || 1

  return {
    alternates: {
      canonical:
        page === 1
          ? 'https://yoursite.com/blog'
          : `https://yoursite.com/blog?page=${page}`,
    },
  }
}
```

## Static Generation

```typescript
// Generate static params for SSG
export async function generateStaticParams() {
  const posts = await db.post.findMany({
    where: { published: true },
    select: { slug: true },
  })

  return posts.map((post) => ({
    slug: post.slug,
  }))
}
```

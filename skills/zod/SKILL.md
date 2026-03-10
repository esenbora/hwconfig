---
name: zod
description: Use when validating data or building schemas. Parsing, error handling, form validation, type inference. Triggers on: zod, validation, schema, parse, safeParse, validate, z.object, z.string.
version: 1.0.0
detect: ["zod"]
---

# Zod

TypeScript-first schema validation.

## Basic Schemas

```typescript
import { z } from 'zod'

// Primitives
const stringSchema = z.string()
const numberSchema = z.number()
const booleanSchema = z.boolean()
const dateSchema = z.date()

// With constraints
const email = z.string().email()
const url = z.string().url()
const uuid = z.string().uuid()
const min = z.string().min(1)
const max = z.string().max(100)
const regex = z.string().regex(/^[a-z]+$/)
const positive = z.number().positive()
const int = z.number().int()
const range = z.number().min(0).max(100)
```

## Object Schemas

```typescript
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().positive().optional(),
  role: z.enum(['user', 'admin']),
  createdAt: z.date(),
})

type User = z.infer<typeof userSchema>

// Parse and validate
const user = userSchema.parse(data) // throws on error
const result = userSchema.safeParse(data) // returns { success, data/error }

if (result.success) {
  console.log(result.data)
} else {
  console.log(result.error.flatten())
}
```

## Common Patterns

```typescript
// Optional and nullable
const optionalString = z.string().optional() // string | undefined
const nullableString = z.string().nullable() // string | null
const nullish = z.string().nullish() // string | null | undefined

// Default values
const withDefault = z.string().default('default')
const withDefaultFn = z.string().default(() => generateId())

// Transform
const trimmed = z.string().trim()
const lowercase = z.string().toLowerCase()
const toNumber = z.string().transform(Number)

// Coerce (auto-convert types)
const coercedNumber = z.coerce.number() // "123" -> 123
const coercedDate = z.coerce.date() // string -> Date

// Refinements
const password = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Must contain uppercase')
  .regex(/[0-9]/, 'Must contain number')

// Custom validation
const even = z.number().refine(n => n % 2 === 0, {
  message: 'Must be even',
})
```

## Arrays and Records

```typescript
// Arrays
const stringArray = z.array(z.string())
const nonEmpty = z.array(z.string()).nonempty()
const limited = z.array(z.string()).min(1).max(10)

// Tuples
const point = z.tuple([z.number(), z.number()])

// Records
const stringRecord = z.record(z.string()) // { [key: string]: string }
const userRecord = z.record(z.string(), userSchema)
```

## Unions and Discriminated Unions

```typescript
// Union
const stringOrNumber = z.union([z.string(), z.number()])

// Discriminated union (better error messages)
const resultSchema = z.discriminatedUnion('status', [
  z.object({ status: z.literal('success'), data: z.string() }),
  z.object({ status: z.literal('error'), error: z.string() }),
])
```

## Form Validation

```typescript
// Create user form
export const createUserSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

// Update user form (partial)
export const updateUserSchema = createUserSchema
  .omit({ confirmPassword: true })
  .partial()

// Server action usage
export async function createUser(formData: FormData) {
  const parsed = createUserSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
    confirmPassword: formData.get('confirmPassword'),
  })

  if (!parsed.success) {
    return {
      success: false,
      errors: parsed.error.flatten().fieldErrors,
    }
  }

  // Create user with parsed.data
}
```

## API Validation

```typescript
// Request schema
const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  published: z.boolean().default(false),
  tags: z.array(z.string()).optional(),
})

// API route
export async function POST(req: Request) {
  const body = await req.json()
  const parsed = createPostSchema.safeParse(body)

  if (!parsed.success) {
    return Response.json(
      { error: 'Validation failed', details: parsed.error.flatten() },
      { status: 400 }
    )
  }

  const post = await db.post.create({ data: parsed.data })
  return Response.json(post)
}
```

## Error Handling

```typescript
try {
  schema.parse(data)
} catch (error) {
  if (error instanceof z.ZodError) {
    // Formatted errors
    console.log(error.flatten())
    // { formErrors: [], fieldErrors: { email: ['Invalid email'] } }

    // All issues
    console.log(error.issues)
    // [{ path: ['email'], message: 'Invalid email', code: 'invalid_string' }]
  }
}
```

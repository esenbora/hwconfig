---
name: typescript
description: Use when writing TypeScript or fixing type errors. Types, generics, utility types, strict mode. Triggers on: typescript, type, generic, interface, type error, ts, typed, typing, infer.
version: 1.0.0
detect: ["tsconfig.json"]
---

# TypeScript

Advanced TypeScript patterns for type-safe applications.

## Configuration

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## Utility Types

```typescript
// Built-in utilities
type Partial<T>      // All props optional
type Required<T>     // All props required
type Readonly<T>     // All props readonly
type Pick<T, K>      // Select specific props
type Omit<T, K>      // Exclude specific props
type Record<K, V>    // Object with keys K and values V
type Exclude<T, U>   // Types in T but not U
type Extract<T, U>   // Types in both T and U
type NonNullable<T>  // Exclude null and undefined
type ReturnType<F>   // Return type of function
type Parameters<F>   // Parameter types of function
type Awaited<T>      // Unwrap Promise type

// Examples
interface User {
  id: string
  name: string
  email: string
  createdAt: Date
}

type CreateUserInput = Omit<User, 'id' | 'createdAt'>
type UserPreview = Pick<User, 'id' | 'name'>
type UpdateUserInput = Partial<CreateUserInput>
```

## Discriminated Unions

```typescript
// State machine pattern
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }

function handleState<T>(state: RequestState<T>) {
  switch (state.status) {
    case 'idle':
      return <IdleView />
    case 'loading':
      return <LoadingView />
    case 'success':
      return <SuccessView data={state.data} />
    case 'error':
      return <ErrorView error={state.error} />
    default:
      // Exhaustive check
      const _exhaustive: never = state
      return _exhaustive
  }
}
```

## Type Guards

```typescript
// typeof guard
function processValue(value: string | number) {
  if (typeof value === 'string') {
    return value.toUpperCase() // string methods available
  }
  return value.toFixed(2) // number methods available
}

// in guard
interface Dog { bark(): void }
interface Cat { meow(): void }

function speak(animal: Dog | Cat) {
  if ('bark' in animal) {
    animal.bark()
  } else {
    animal.meow()
  }
}

// Custom type guard
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value &&
    typeof (value as User).id === 'string'
  )
}

// Usage
function processInput(input: unknown) {
  if (isUser(input)) {
    console.log(input.email) // TypeScript knows it's User
  }
}
```

## Generics

```typescript
// Generic function
function first<T>(array: T[]): T | undefined {
  return array[0]
}

// Generic with constraint
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

// Generic interface
interface ApiResponse<T> {
  data: T
  status: number
  message: string
}

// Generic component
interface ListProps<T> {
  items: T[]
  renderItem: (item: T) => React.ReactNode
  keyExtractor: (item: T) => string
}

function List<T>({ items, renderItem, keyExtractor }: ListProps<T>) {
  return (
    <ul>
      {items.map(item => (
        <li key={keyExtractor(item)}>{renderItem(item)}</li>
      ))}
    </ul>
  )
}

// Usage with inference
<List
  items={users}
  renderItem={user => user.name}
  keyExtractor={user => user.id}
/>
```

## Mapped Types

```typescript
// Make all props optional
type Optional<T> = {
  [K in keyof T]?: T[K]
}

// Make all props readonly
type Immutable<T> = {
  readonly [K in keyof T]: T[K]
}

// Add prefix to keys
type Prefixed<T, P extends string> = {
  [K in keyof T as `${P}${Capitalize<string & K>}`]: T[K]
}

// Filter props by type
type StringProps<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K]
}
```

## Template Literal Types

```typescript
type EventName = 'click' | 'focus' | 'blur'
type EventHandler = `on${Capitalize<EventName>}` // 'onClick' | 'onFocus' | 'onBlur'

type Route = `/${string}`
type ApiRoute = `/api/${string}`

// Combine with mapped types
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

interface Person {
  name: string
  age: number
}

type PersonGetters = Getters<Person>
// { getName: () => string; getAge: () => number }
```

## Conditional Types

```typescript
// Basic conditional
type IsString<T> = T extends string ? true : false

// Extract return type
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T

// Conditional with inference
type ArrayElement<T> = T extends (infer E)[] ? E : never

// Distributed conditional
type NonNullableDeep<T> = T extends object
  ? { [K in keyof T]: NonNullableDeep<NonNullable<T[K]>> }
  : NonNullable<T>
```

## Assertion Functions

```typescript
function assertDefined<T>(
  value: T | null | undefined,
  message?: string
): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error(message ?? 'Value is not defined')
  }
}

// Usage
function processUser(user: User | null) {
  assertDefined(user, 'User is required')
  // TypeScript knows user is User here
  console.log(user.email)
}
```

## Module Augmentation

```typescript
// Extend existing types
declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      role: 'admin' | 'user'
    } & DefaultSession['user']
  }
}

// Extend global
declare global {
  interface Window {
    analytics: {
      track: (event: string, props?: object) => void
    }
  }
}
```

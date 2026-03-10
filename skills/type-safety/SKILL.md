---
name: type-safety
description: Use when writing TypeScript. Strict mode, no any, proper generics. Always active.
version: 1.0.0
---

# Type Safety

TypeScript is not optional. Strict mode is not optional. Types prevent bugs that tests miss.

## Strict Mode Requirements

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## No `any` Types

```typescript
// ❌ Never do this
function processData(data: any) { }
const result: any = fetchData()

// ✅ Use proper types
function processData(data: UserData) { }
const result: ApiResponse<User> = await fetchData()

// ✅ If truly unknown, use unknown and narrow
function processUnknown(data: unknown) {
  if (isUserData(data)) {
    // data is now typed as UserData
  }
}
```

## Type Narrowing

### Type Guards

```typescript
// Custom type guard
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  )
}

// Usage
function processInput(input: unknown) {
  if (isUser(input)) {
    // TypeScript knows input is User here
    console.log(input.email)
  }
}
```

### Discriminated Unions

```typescript
// ❌ Boolean flags
interface State {
  isLoading: boolean
  isError: boolean
  data: Data | null
  error: Error | null
}
// Bug: isLoading and isError can both be true

// ✅ Discriminated union
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: Data }
  | { status: 'error'; error: Error }

// Usage with exhaustive checking
function render(state: State) {
  switch (state.status) {
    case 'idle':
      return <IdleState />
    case 'loading':
      return <LoadingState />
    case 'success':
      return <SuccessState data={state.data} />
    case 'error':
      return <ErrorState error={state.error} />
    default:
      // Ensures all cases handled
      const _exhaustive: never = state
      return _exhaustive
  }
}
```

## Generics

### When to Use

```typescript
// Generic function
function first<T>(array: T[]): T | undefined {
  return array[0]
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
  renderItem={user => <UserCard user={user} />}
  keyExtractor={user => user.id}
/>
```

### Constraints

```typescript
// Constrain generic types
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

// With base type
interface HasId {
  id: string
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id)
}
```

## Utility Types

```typescript
// Partial - all properties optional
type UpdateUser = Partial<User>

// Required - all properties required
type CompleteUser = Required<User>

// Pick - select properties
type UserPreview = Pick<User, 'id' | 'name' | 'avatar'>

// Omit - exclude properties
type CreateUserInput = Omit<User, 'id' | 'createdAt'>

// Record - typed object
type UserById = Record<string, User>

// ReturnType - infer from function
type ApiResult = ReturnType<typeof fetchUser>

// Parameters - infer function params
type FetchParams = Parameters<typeof fetchUser>
```

## Zod Integration

```typescript
import { z } from 'zod'

// Define schema
const userSchema = z.object({
  id: z.string().cuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user']),
  createdAt: z.date(),
})

// Infer TypeScript type from schema
type User = z.infer<typeof userSchema>

// Runtime validation with type safety
function validateUser(input: unknown): User {
  return userSchema.parse(input) // Throws if invalid
}

// Safe validation
function safeValidateUser(input: unknown): User | null {
  const result = userSchema.safeParse(input)
  return result.success ? result.data : null
}
```

## API Types

```typescript
// Response wrapper
interface ApiResponse<T> {
  data: T
  meta?: {
    page: number
    total: number
  }
}

interface ApiError {
  error: string
  code: string
  field?: string
}

type ApiResult<T> = ApiResponse<T> | ApiError

// Type guard for error
function isApiError(result: ApiResult<unknown>): result is ApiError {
  return 'error' in result
}
```

## React Types

```typescript
// Component props
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
  isLoading?: boolean
}

// Event handlers
const handleClick: React.MouseEventHandler<HTMLButtonElement> = (e) => { }
const handleChange: React.ChangeEventHandler<HTMLInputElement> = (e) => { }
const handleSubmit: React.FormEventHandler<HTMLFormElement> = (e) => { }

// Ref types
const inputRef = useRef<HTMLInputElement>(null)
const formRef = useRef<HTMLFormElement>(null)

// Children types
interface LayoutProps {
  children: React.ReactNode // Most flexible
}

interface CardProps {
  children: React.ReactElement // Single element only
}
```

---
name: react-19
description: Use when using React 19 features. use() hook, Server Components, Actions, useOptimistic, useFormStatus. Triggers on: react 19, use hook, useOptimistic, useFormStatus, server action, react server.
version: 1.0.0
---

# React 19 Patterns (2026)

> **Priority:** RECOMMENDED | **Auto-Load:** On React work
> **Triggers:** react 19, use hook, server actions, form actions, useActionState, useFormStatus, useOptimistic

---

## Overview

React 19 (stable December 2024) introduces new hooks and patterns for improved data fetching, form handling, and optimistic updates.

---

## New Hooks

### use() - Universal Async Data Fetching

The `use()` hook can read resources (Promises, Contexts) and suspends the component until resolved.

```typescript
import { use, Suspense } from 'react';

// Basic Promise reading
function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);  // Suspends until resolved
  return <div>{user.name}</div>;
}

// Usage with Suspense boundary
function Page({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);  // Start fetching immediately

  return (
    <Suspense fallback={<LoadingSkeleton />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}

// Conditional use() - Can be called inside conditions!
function MessageComponent({ messagePromise, shouldShow }) {
  if (!shouldShow) return null;

  // Unlike hooks, use() CAN be called conditionally
  const message = use(messagePromise);
  return <p>{message}</p>;
}

// Context reading with use()
function ThemeButton() {
  // Alternative to useContext()
  const theme = use(ThemeContext);
  return <button className={theme}>Click</button>;
}
```

**Key differences from other hooks:**
- Can be called inside loops and conditionals
- Works with Promises and Contexts
- Integrates with Suspense for loading states
- Replaces many use cases for useEffect data fetching

---

### useActionState - Form State Management

Manages form submission state, replacing the deprecated `useFormState`.

```typescript
import { useActionState } from 'react';

// Server action (in separate file with 'use server')
async function submitForm(prevState: FormState, formData: FormData) {
  'use server';

  const email = formData.get('email');

  try {
    await subscribeToNewsletter(email);
    return { success: true, message: 'Subscribed!' };
  } catch (error) {
    return { success: false, message: 'Failed to subscribe' };
  }
}

// Component
function NewsletterForm() {
  const [state, formAction, isPending] = useActionState(submitForm, {
    success: false,
    message: '',
  });

  return (
    <form action={formAction}>
      <input
        name="email"
        type="email"
        disabled={isPending}
        placeholder="Enter email"
      />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Subscribing...' : 'Subscribe'}
      </button>
      {state.message && (
        <p className={state.success ? 'text-green-500' : 'text-red-500'}>
          {state.message}
        </p>
      )}
    </form>
  );
}
```

**Return values:**
- `state` - Current form state (returned from action)
- `formAction` - Action to pass to form/button
- `isPending` - Boolean indicating submission in progress

---

### useFormStatus - Form Submission State

Reads the status of a parent `<form>`. Must be used within a form.

```typescript
import { useFormStatus } from 'react-dom';

// Must be a child of <form> with action
function SubmitButton() {
  const { pending, data, method, action } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

// Usage
function ContactForm() {
  return (
    <form action={serverAction}>
      <input name="message" />
      <SubmitButton />  {/* Can read form status */}
    </form>
  );
}

// Loading indicator
function FormLoadingIndicator() {
  const { pending } = useFormStatus();

  if (!pending) return null;

  return (
    <div className="absolute inset-0 bg-white/50 flex items-center justify-center">
      <Spinner />
    </div>
  );
}
```

---

### useOptimistic - Optimistic Updates

Show optimistic UI state while async operations complete.

```typescript
import { useOptimistic } from 'react';

function MessageList({ messages, sendMessage }) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    // Update function: (currentState, optimisticValue) => newState
    (state, newMessage) => [
      ...state,
      { ...newMessage, sending: true },
    ]
  );

  async function handleSend(formData: FormData) {
    const text = formData.get('text');
    const newMessage = { id: crypto.randomUUID(), text };

    // Add optimistic message immediately
    addOptimisticMessage(newMessage);

    // Send to server (message will be replaced when messages prop updates)
    await sendMessage(text);
  }

  return (
    <div>
      {optimisticMessages.map((message) => (
        <div
          key={message.id}
          className={message.sending ? 'opacity-50' : ''}
        >
          {message.text}
          {message.sending && <span> (sending...)</span>}
        </div>
      ))}
      <form action={handleSend}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </div>
  );
}
```

**Pattern for likes/toggles:**

```typescript
function LikeButton({ isLiked, onLike }) {
  const [optimisticLiked, setOptimisticLiked] = useOptimistic(isLiked);

  async function handleClick() {
    setOptimisticLiked(!optimisticLiked);  // Immediate UI feedback
    await onLike();  // Server call
  }

  return (
    <button onClick={handleClick}>
      {optimisticLiked ? '❤️' : '🤍'}
    </button>
  );
}
```

---

## Form Actions

### Basic Form Action

```typescript
// Server action
async function createPost(formData: FormData) {
  'use server';

  const title = formData.get('title') as string;
  const content = formData.get('content') as string;

  await db.post.create({ data: { title, content } });
  revalidatePath('/posts');
}

// Form with action
function CreatePostForm() {
  return (
    <form action={createPost}>
      <input name="title" placeholder="Title" required />
      <textarea name="content" placeholder="Content" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

### Form with Validation and Error Handling

```typescript
import { z } from 'zod';

const postSchema = z.object({
  title: z.string().min(1, 'Title required').max(100, 'Title too long'),
  content: z.string().min(10, 'Content too short'),
});

type FormState = {
  errors?: { title?: string[]; content?: string[] };
  success?: boolean;
};

async function createPost(prevState: FormState, formData: FormData): Promise<FormState> {
  'use server';

  const result = postSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });

  if (!result.success) {
    return { errors: result.error.flatten().fieldErrors };
  }

  await db.post.create({ data: result.data });
  revalidatePath('/posts');
  return { success: true };
}

function CreatePostForm() {
  const [state, action, pending] = useActionState(createPost, {});

  return (
    <form action={action}>
      <div>
        <input name="title" placeholder="Title" />
        {state.errors?.title && (
          <p className="text-red-500">{state.errors.title[0]}</p>
        )}
      </div>
      <div>
        <textarea name="content" placeholder="Content" />
        {state.errors?.content && (
          <p className="text-red-500">{state.errors.content[0]}</p>
        )}
      </div>
      <button type="submit" disabled={pending}>
        {pending ? 'Creating...' : 'Create Post'}
      </button>
      {state.success && <p className="text-green-500">Post created!</p>}
    </form>
  );
}
```

---

## Ref Improvements

### Refs as Props (No forwardRef needed)

```typescript
// React 19 - ref directly as prop
function Input({ ref, ...props }) {
  return <input ref={ref} {...props} />;
}

// Usage
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);

  return <Input ref={inputRef} placeholder="Name" />;
}

// Old way (still works but unnecessary)
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => {
  return <input ref={ref} {...props} />;
});
```

### Cleanup Functions in Refs

```typescript
function VideoPlayer({ src }) {
  return (
    <video
      ref={(video) => {
        if (video) {
          video.play();
        }
        // Cleanup function - runs on unmount
        return () => {
          video?.pause();
        };
      }}
      src={src}
    />
  );
}
```

---

## Document Metadata

### Native Title and Meta Support

```typescript
function BlogPost({ post }) {
  return (
    <article>
      {/* These hoist to <head> automatically */}
      <title>{post.title} | My Blog</title>
      <meta name="description" content={post.excerpt} />
      <meta property="og:title" content={post.title} />
      <link rel="canonical" href={`/posts/${post.slug}`} />

      {/* Stylesheets with precedence */}
      <link rel="stylesheet" href="/styles/blog.css" precedence="default" />
      <link rel="stylesheet" href="/styles/post.css" precedence="high" />

      <h1>{post.title}</h1>
      <div>{post.content}</div>
    </article>
  );
}
```

---

## Async Script Loading

```typescript
function Analytics() {
  return (
    <>
      {/* Async scripts deduplicated automatically */}
      <script async src="https://analytics.example.com/script.js" />
    </>
  );
}

// Multiple components can request same script - only loads once
function Header() {
  return (
    <>
      <script async src="https://analytics.example.com/script.js" />
      <nav>...</nav>
    </>
  );
}
```

---

## Migration Patterns

### From useEffect Data Fetching

```typescript
// Old pattern (React 18)
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetchUser(userId).then(data => {
      setUser(data);
      setLoading(false);
    });
  }, [userId]);

  if (loading) return <Spinner />;
  return <div>{user.name}</div>;
}

// New pattern (React 19)
function UserProfile({ userPromise }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}

// Parent component
function Page({ userId }) {
  const userPromise = fetchUser(userId);  // Start fetch immediately

  return (
    <Suspense fallback={<Spinner />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### From useState + fetch to useActionState

```typescript
// Old pattern
function NewsletterForm() {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    const formData = new FormData(e.target);
    const result = await subscribeAction(formData);
    setMessage(result.message);
    setLoading(false);
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" />
      <button disabled={loading}>Subscribe</button>
      {message && <p>{message}</p>}
    </form>
  );
}

// New pattern (React 19)
function NewsletterForm() {
  const [state, action, pending] = useActionState(subscribeAction, { message: '' });

  return (
    <form action={action}>
      <input name="email" />
      <button disabled={pending}>Subscribe</button>
      {state.message && <p>{state.message}</p>}
    </form>
  );
}
```

---

## Best Practices

### 1. Start Data Fetching Early

```typescript
// Good - fetch starts immediately
function Page() {
  const dataPromise = fetchData();  // Starts here
  return (
    <Suspense fallback={<Loading />}>
      <Content dataPromise={dataPromise} />
    </Suspense>
  );
}

// Better - fetch in loader/RSC
export async function loader() {
  return { dataPromise: fetchData() };
}
```

### 2. Use Suspense Boundaries Strategically

```typescript
function Dashboard() {
  return (
    <div>
      <Header />
      {/* Independent loading states */}
      <Suspense fallback={<ChartSkeleton />}>
        <Chart dataPromise={chartData} />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <DataTable dataPromise={tableData} />
      </Suspense>
    </div>
  );
}
```

### 3. Combine with TanStack Query for Caching

```typescript
import { useSuspenseQuery } from '@tanstack/react-query';

function UserProfile({ userId }) {
  const { data: user } = useSuspenseQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });

  return <div>{user.name}</div>;
}
```

---

## Quick Reference

| Hook | Purpose | Returns |
|------|---------|---------|
| `use(promise)` | Read async data | Resolved value |
| `use(context)` | Read context | Context value |
| `useActionState(action, initial)` | Form state | `[state, formAction, isPending]` |
| `useFormStatus()` | Parent form state | `{ pending, data, method, action }` |
| `useOptimistic(state, updateFn)` | Optimistic UI | `[optimisticState, addOptimistic]` |

---

## Resources

- [React 19 Blog Post](https://react.dev/blog/2024/12/05/react-19)
- [React 19 Upgrade Guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide)
- [useActionState Docs](https://react.dev/reference/react/useActionState)
- [use() Hook Docs](https://react.dev/reference/react/use)

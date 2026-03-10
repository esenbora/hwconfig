---
name: trpc
description: Use when building type-safe APIs with tRPC. Routers, procedures, React Query integration. Triggers on: trpc, type-safe api, procedure, router, trpc router, trpc query.
version: 1.0.0
---

# tRPC Deep Knowledge

> Middleware, transformers, subscriptions, and advanced patterns.

---

## Quick Reference

```typescript
// Server
const appRouter = router({
  hello: publicProcedure.query(() => 'Hello World'),
});

// Client
const result = await trpc.hello.query();
```

---

## Router Setup

### Complete Server Setup

```typescript
// server/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server';
import { Context } from './context';
import superjson from 'superjson';
import { ZodError } from 'zod';

const t = initTRPC.context<Context>().create({
  transformer: superjson,
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError:
          error.cause instanceof ZodError ? error.cause.flatten() : null,
      },
    };
  },
});

export const router = t.router;
export const publicProcedure = t.procedure;
export const middleware = t.middleware;
export const mergeRouters = t.mergeRouters;
```

### Context Creation

```typescript
// server/context.ts
import { inferAsyncReturnType } from '@trpc/server';
import { CreateNextContextOptions } from '@trpc/server/adapters/next';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function createContext({ req, res }: CreateNextContextOptions) {
  const session = await getServerSession(req, res, authOptions);
  
  return {
    prisma,
    session,
    user: session?.user,
    req,
    res,
  };
}

export type Context = inferAsyncReturnType<typeof createContext>;
```

---

## Middleware

### Authentication Middleware

```typescript
const isAuthed = middleware(({ ctx, next }) => {
  if (!ctx.session || !ctx.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }
  return next({
    ctx: {
      ...ctx,
      user: ctx.user, // user is now non-nullable
    },
  });
});

export const protectedProcedure = publicProcedure.use(isAuthed);
```

### Role-Based Middleware

```typescript
const hasRole = (requiredRole: string) =>
  middleware(({ ctx, next }) => {
    if (!ctx.user) {
      throw new TRPCError({ code: 'UNAUTHORIZED' });
    }
    if (ctx.user.role !== requiredRole) {
      throw new TRPCError({ code: 'FORBIDDEN' });
    }
    return next({ ctx });
  });

export const adminProcedure = protectedProcedure.use(hasRole('admin'));
```

### Logging Middleware

```typescript
const logger = middleware(async ({ path, type, next }) => {
  const start = Date.now();
  
  const result = await next();
  
  const duration = Date.now() - start;
  console.log(`${type} ${path} - ${duration}ms`);
  
  return result;
});

export const loggedProcedure = publicProcedure.use(logger);
```

### Rate Limiting Middleware

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'),
});

const rateLimiter = middleware(async ({ ctx, next }) => {
  const identifier = ctx.user?.id || ctx.req.headers['x-forwarded-for'];
  
  const { success, remaining, reset } = await ratelimit.limit(identifier);
  
  if (!success) {
    throw new TRPCError({
      code: 'TOO_MANY_REQUESTS',
      message: `Rate limited. Try again in ${Math.ceil((reset - Date.now()) / 1000)}s`,
    });
  }
  
  return next();
});

export const rateLimitedProcedure = publicProcedure.use(rateLimiter);
```

---

## Procedures

### Input Validation

```typescript
import { z } from 'zod';

const userRouter = router({
  create: protectedProcedure
    .input(
      z.object({
        email: z.string().email(),
        name: z.string().min(1).max(100),
        role: z.enum(['user', 'admin']).default('user'),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const user = await ctx.prisma.user.create({
        data: input,
      });
      return user;
    }),
    
  getById: publicProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ ctx, input }) => {
      const user = await ctx.prisma.user.findUnique({
        where: { id: input.id },
      });
      if (!user) {
        throw new TRPCError({ code: 'NOT_FOUND' });
      }
      return user;
    }),
});
```

### Output Validation

```typescript
const userRouter = router({
  getProfile: protectedProcedure
    .output(
      z.object({
        id: z.string(),
        email: z.string(),
        name: z.string(),
        // Exclude sensitive fields
      })
    )
    .query(async ({ ctx }) => {
      const user = await ctx.prisma.user.findUnique({
        where: { id: ctx.user.id },
      });
      return user;
    }),
});
```

### Mutation with Transaction

```typescript
const orderRouter = router({
  create: protectedProcedure
    .input(z.object({
      items: z.array(z.object({
        productId: z.string(),
        quantity: z.number().positive(),
      })),
    }))
    .mutation(async ({ ctx, input }) => {
      return ctx.prisma.$transaction(async (tx) => {
        // Create order
        const order = await tx.order.create({
          data: {
            userId: ctx.user.id,
            status: 'pending',
          },
        });
        
        // Create order items and update inventory
        for (const item of input.items) {
          await tx.orderItem.create({
            data: {
              orderId: order.id,
              ...item,
            },
          });
          
          await tx.product.update({
            where: { id: item.productId },
            data: {
              stock: { decrement: item.quantity },
            },
          });
        }
        
        return order;
      });
    }),
});
```

---

## Subscriptions (WebSocket)

### Server Setup

```typescript
// server/wsServer.ts
import { applyWSSHandler } from '@trpc/server/adapters/ws';
import ws from 'ws';
import { appRouter } from './routers';
import { createContext } from './context';

const wss = new ws.Server({ port: 3001 });

applyWSSHandler({
  wss,
  router: appRouter,
  createContext,
});

// Router with subscription
const chatRouter = router({
  onMessage: publicProcedure
    .input(z.object({ roomId: z.string() }))
    .subscription(({ input }) => {
      return observable<Message>((emit) => {
        const onMessage = (message: Message) => {
          if (message.roomId === input.roomId) {
            emit.next(message);
          }
        };
        
        eventEmitter.on('message', onMessage);
        
        return () => {
          eventEmitter.off('message', onMessage);
        };
      });
    }),
    
  sendMessage: protectedProcedure
    .input(z.object({
      roomId: z.string(),
      content: z.string(),
    }))
    .mutation(async ({ ctx, input }) => {
      const message = await ctx.prisma.message.create({
        data: {
          ...input,
          userId: ctx.user.id,
        },
      });
      
      eventEmitter.emit('message', message);
      
      return message;
    }),
});
```

### Client Subscription

```typescript
// React component
function ChatRoom({ roomId }: { roomId: string }) {
  const [messages, setMessages] = useState<Message[]>([]);
  
  trpc.chat.onMessage.useSubscription(
    { roomId },
    {
      onData(message) {
        setMessages((prev) => [...prev, message]);
      },
      onError(err) {
        console.error('Subscription error:', err);
      },
    }
  );
  
  return <MessageList messages={messages} />;
}
```

---

## Error Handling

### Custom Errors

```typescript
import { TRPCError } from '@trpc/server';

// In procedure
throw new TRPCError({
  code: 'BAD_REQUEST',
  message: 'Email already exists',
  cause: originalError,
});

// Error codes:
// PARSE_ERROR, BAD_REQUEST, UNAUTHORIZED, FORBIDDEN,
// NOT_FOUND, METHOD_NOT_SUPPORTED, TIMEOUT, CONFLICT,
// PRECONDITION_FAILED, PAYLOAD_TOO_LARGE, TOO_MANY_REQUESTS,
// CLIENT_CLOSED_REQUEST, INTERNAL_SERVER_ERROR
```

### Global Error Handler

```typescript
// client/trpc.ts
const trpc = createTRPCReact<AppRouter>();

const trpcClient = trpc.createClient({
  links: [
    httpBatchLink({
      url: '/api/trpc',
      // Custom error handling
      fetch: async (url, options) => {
        const response = await fetch(url, options);
        
        if (!response.ok) {
          // Handle network errors
        }
        
        return response;
      },
    }),
  ],
});
```

---

## Optimistic Updates

```typescript
function TodoList() {
  const utils = trpc.useUtils();
  
  const addTodo = trpc.todo.create.useMutation({
    onMutate: async (newTodo) => {
      // Cancel outgoing fetches
      await utils.todo.list.cancel();
      
      // Snapshot current data
      const previousTodos = utils.todo.list.getData();
      
      // Optimistically update
      utils.todo.list.setData(undefined, (old) => [
        ...(old ?? []),
        { id: 'temp', ...newTodo, createdAt: new Date() },
      ]);
      
      return { previousTodos };
    },
    
    onError: (err, newTodo, context) => {
      // Rollback on error
      utils.todo.list.setData(undefined, context?.previousTodos);
    },
    
    onSettled: () => {
      // Refetch to sync
      utils.todo.list.invalidate();
    },
  });
  
  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      addTodo.mutate({ title: inputValue });
    }}>
      {/* ... */}
    </form>
  );
}
```

---

## Batching & Caching

### Request Batching

```typescript
// Automatic batching with httpBatchLink
const trpcClient = trpc.createClient({
  links: [
    httpBatchLink({
      url: '/api/trpc',
      maxURLLength: 2083, // Batch limit
    }),
  ],
});

// Multiple queries automatically batched
const { data: user } = trpc.user.get.useQuery();
const { data: posts } = trpc.post.list.useQuery();
// → Single HTTP request with both queries
```

### React Query Integration

```typescript
// Cache configuration
function MyApp({ Component, pageProps }: AppProps) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 5 * 60 * 1000, // 5 minutes
            refetchOnWindowFocus: false,
          },
        },
      })
  );
  
  const [trpcClient] = useState(() =>
    trpc.createClient({ /* ... */ })
  );
  
  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>
        <Component {...pageProps} />
      </QueryClientProvider>
    </trpc.Provider>
  );
}
```

---

## Testing

```typescript
import { inferProcedureInput } from '@trpc/server';
import { createInnerTRPCContext } from '../context';
import { appRouter, AppRouter } from '../routers';

describe('userRouter', () => {
  const ctx = createInnerTRPCContext({
    session: { user: { id: '1', role: 'admin' } },
  });
  
  const caller = appRouter.createCaller(ctx);
  
  it('should create user', async () => {
    type Input = inferProcedureInput<AppRouter['user']['create']>;
    const input: Input = { email: 'test@example.com', name: 'Test' };
    
    const user = await caller.user.create(input);
    
    expect(user.email).toBe('test@example.com');
  });
  
  it('should throw on unauthorized', async () => {
    const unauthCtx = createInnerTRPCContext({ session: null });
    const unauthCaller = appRouter.createCaller(unauthCtx);
    
    await expect(unauthCaller.user.create({ ... }))
      .rejects.toThrow('UNAUTHORIZED');
  });
});
```

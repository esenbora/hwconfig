---
name: react-query
description: Use when fetching data, managing server state, or caching API responses. useQuery, useMutation, TanStack Query. Triggers on: react query, tanstack query, useQuery, useMutation, server state, data fetching, cache, stale, refetch.
version: 1.0.0
---

# TanStack Query (React Query) Deep Knowledge

> Cache strategies, optimistic updates, infinite queries, and advanced patterns.

---

## Quick Reference

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

const { data, isLoading, error } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
});
```

---

## Query Configuration

### Query Client Setup

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 30, // 30 minutes (was cacheTime)
      retry: 3,
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
      refetchOnMount: true,
    },
    mutations: {
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <MyApp />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

### Query Options

```typescript
const { data, isLoading, isFetching, isError, error, status, fetchStatus } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetchUser(userId),
  
  // Caching
  staleTime: 1000 * 60, // Data fresh for 1 minute
  gcTime: 1000 * 60 * 5, // Keep unused data for 5 minutes
  
  // Refetching
  refetchInterval: 1000 * 30, // Refetch every 30s
  refetchIntervalInBackground: false,
  refetchOnWindowFocus: true,
  
  // Conditional
  enabled: !!userId, // Only run when userId exists
  
  // Initial data
  initialData: cachedUser,
  initialDataUpdatedAt: Date.now() - 1000 * 60, // Treat as 1 min old
  placeholderData: previousUser,
  
  // Selection
  select: (data) => data.name, // Transform data
  
  // Network mode
  networkMode: 'offlineFirst', // 'online' | 'always' | 'offlineFirst'
  
  // Behavior
  throwOnError: false,
  notifyOnChangeProps: ['data', 'error'], // Only re-render on these changes
});
```

---

## Query Keys Best Practices

```typescript
// Simple key
const { data } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
});

// With ID
const { data } = useQuery({
  queryKey: ['todo', todoId],
  queryFn: () => fetchTodo(todoId),
});

// With filters
const { data } = useQuery({
  queryKey: ['todos', { status, page, sort }],
  queryFn: () => fetchTodos({ status, page, sort }),
});

// Factory pattern (recommended)
const todoKeys = {
  all: ['todos'] as const,
  lists: () => [...todoKeys.all, 'list'] as const,
  list: (filters: TodoFilters) => [...todoKeys.lists(), filters] as const,
  details: () => [...todoKeys.all, 'detail'] as const,
  detail: (id: number) => [...todoKeys.details(), id] as const,
};

// Usage
useQuery({ queryKey: todoKeys.detail(5), queryFn: () => fetchTodo(5) });
useQuery({ queryKey: todoKeys.list({ status: 'done' }), queryFn: ... });

// Invalidation with factory
queryClient.invalidateQueries({ queryKey: todoKeys.all }); // All todo queries
queryClient.invalidateQueries({ queryKey: todoKeys.lists() }); // All lists
queryClient.invalidateQueries({ queryKey: todoKeys.detail(5) }); // Specific detail
```

---

## Mutations

### Basic Mutation

```typescript
const mutation = useMutation({
  mutationFn: (newTodo: Todo) => api.createTodo(newTodo),
  
  onMutate: async (newTodo) => {
    // Called before mutation
    console.log('Creating:', newTodo);
  },
  
  onSuccess: (data, variables, context) => {
    // Called on success
    console.log('Created:', data);
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  },
  
  onError: (error, variables, context) => {
    // Called on error
    console.error('Failed:', error);
  },
  
  onSettled: (data, error, variables, context) => {
    // Called on success or error
    console.log('Done');
  },
});

// Usage
mutation.mutate({ title: 'New Todo' });

// With callbacks
mutation.mutate(
  { title: 'New Todo' },
  {
    onSuccess: () => navigate('/todos'),
    onError: () => alert('Failed!'),
  }
);

// Async
const data = await mutation.mutateAsync({ title: 'New Todo' });
```

---

## Optimistic Updates

### Pattern 1: Update Cache Immediately

```typescript
const queryClient = useQueryClient();

const mutation = useMutation({
  mutationFn: updateTodo,
  
  onMutate: async (updatedTodo) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries({ queryKey: ['todos', updatedTodo.id] });
    
    // Snapshot previous value
    const previousTodo = queryClient.getQueryData(['todos', updatedTodo.id]);
    
    // Optimistically update cache
    queryClient.setQueryData(['todos', updatedTodo.id], updatedTodo);
    
    // Return context for rollback
    return { previousTodo };
  },
  
  onError: (err, updatedTodo, context) => {
    // Rollback on error
    queryClient.setQueryData(
      ['todos', updatedTodo.id],
      context?.previousTodo
    );
  },
  
  onSettled: (data, error, variables) => {
    // Always refetch to ensure sync
    queryClient.invalidateQueries({ queryKey: ['todos', variables.id] });
  },
});
```

### Pattern 2: Optimistic List Update

```typescript
const queryClient = useQueryClient();

const addTodoMutation = useMutation({
  mutationFn: createTodo,
  
  onMutate: async (newTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] });
    
    const previousTodos = queryClient.getQueryData<Todo[]>(['todos']);
    
    // Add optimistic todo with temp ID
    queryClient.setQueryData<Todo[]>(['todos'], (old) => [
      ...(old || []),
      { ...newTodo, id: Date.now(), isPending: true },
    ]);
    
    return { previousTodos };
  },
  
  onError: (err, newTodo, context) => {
    queryClient.setQueryData(['todos'], context?.previousTodos);
  },
  
  onSuccess: (data, variables) => {
    // Replace optimistic with real data
    queryClient.setQueryData<Todo[]>(['todos'], (old) =>
      old?.map((todo) =>
        todo.isPending && todo.title === variables.title ? data : todo
      )
    );
  },
  
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  },
});
```

---

## Infinite Queries

```typescript
import { useInfiniteQuery } from '@tanstack/react-query';

interface Page {
  data: Todo[];
  nextCursor?: number;
}

const {
  data,
  fetchNextPage,
  fetchPreviousPage,
  hasNextPage,
  hasPreviousPage,
  isFetchingNextPage,
  isFetchingPreviousPage,
} = useInfiniteQuery({
  queryKey: ['todos', 'infinite'],
  queryFn: ({ pageParam }) => fetchTodos({ cursor: pageParam, limit: 20 }),
  
  initialPageParam: 0,
  
  getNextPageParam: (lastPage, allPages) => lastPage.nextCursor,
  getPreviousPageParam: (firstPage, allPages) => firstPage.prevCursor,
  
  maxPages: 5, // Keep only 5 pages in cache
});

// Render all pages
return (
  <div>
    {data?.pages.map((page, i) => (
      <React.Fragment key={i}>
        {page.data.map((todo) => (
          <TodoItem key={todo.id} todo={todo} />
        ))}
      </React.Fragment>
    ))}
    
    <button
      onClick={() => fetchNextPage()}
      disabled={!hasNextPage || isFetchingNextPage}
    >
      {isFetchingNextPage ? 'Loading...' : hasNextPage ? 'Load More' : 'No More'}
    </button>
  </div>
);
```

### Infinite Query with Virtual List

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

function TodoList() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } =
    useInfiniteQuery({ /* ... */ });
  
  const allTodos = data?.pages.flatMap((page) => page.data) ?? [];
  
  const parentRef = useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: hasNextPage ? allTodos.length + 1 : allTodos.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  });
  
  const items = virtualizer.getVirtualItems();
  
  useEffect(() => {
    const lastItem = items[items.length - 1];
    
    if (
      lastItem &&
      lastItem.index >= allTodos.length - 1 &&
      hasNextPage &&
      !isFetchingNextPage
    ) {
      fetchNextPage();
    }
  }, [items, hasNextPage, isFetchingNextPage, allTodos.length, fetchNextPage]);
  
  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {items.map((virtualRow) => {
          const todo = allTodos[virtualRow.index];
          return (
            <div
              key={virtualRow.key}
              style={{
                position: 'absolute',
                top: virtualRow.start,
                height: virtualRow.size,
              }}
            >
              {todo ? <TodoItem todo={todo} /> : 'Loading...'}
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

---

## Prefetching

```typescript
const queryClient = useQueryClient();

// Prefetch on mount
useEffect(() => {
  queryClient.prefetchQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  });
}, []);

// Prefetch on hover
function TodoLink({ todoId }: { todoId: number }) {
  const queryClient = useQueryClient();
  
  const prefetch = () => {
    queryClient.prefetchQuery({
      queryKey: ['todo', todoId],
      queryFn: () => fetchTodo(todoId),
      staleTime: 1000 * 60 * 5, // Prefetch only if older than 5 min
    });
  };
  
  return (
    <Link href={`/todo/${todoId}`} onMouseEnter={prefetch}>
      View Todo
    </Link>
  );
}

// Prefetch infinite query
queryClient.prefetchInfiniteQuery({
  queryKey: ['todos', 'infinite'],
  queryFn: fetchTodosPage,
  initialPageParam: 0,
});
```

---

## Dependent Queries

```typescript
// Sequential queries
function UserPosts({ userId }: { userId: string }) {
  // First query
  const { data: user } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });
  
  // Second query (depends on first)
  const { data: posts } = useQuery({
    queryKey: ['posts', user?.id],
    queryFn: () => fetchPostsByUser(user!.id),
    enabled: !!user?.id, // Only run when user exists
  });
  
  // Third query (depends on second)
  const { data: comments } = useQuery({
    queryKey: ['comments', posts?.[0]?.id],
    queryFn: () => fetchComments(posts![0].id),
    enabled: !!posts?.[0]?.id,
  });
}
```

---

## Parallel Queries

```typescript
// Multiple queries in parallel
function Dashboard() {
  const userQuery = useQuery({ queryKey: ['user'], queryFn: fetchUser });
  const postsQuery = useQuery({ queryKey: ['posts'], queryFn: fetchPosts });
  const statsQuery = useQuery({ queryKey: ['stats'], queryFn: fetchStats });
  
  const isLoading = userQuery.isLoading || postsQuery.isLoading || statsQuery.isLoading;
  
  if (isLoading) return <Loading />;
}

// Using useQueries for dynamic parallel queries
import { useQueries } from '@tanstack/react-query';

function UsersList({ userIds }: { userIds: string[] }) {
  const userQueries = useQueries({
    queries: userIds.map((id) => ({
      queryKey: ['user', id],
      queryFn: () => fetchUser(id),
    })),
    combine: (results) => ({
      data: results.map((result) => result.data),
      pending: results.some((result) => result.isPending),
    }),
  });
  
  return userQueries.pending ? <Loading /> : <UserList users={userQueries.data} />;
}
```

---

## SSR with Next.js

### App Router (RSC)

```typescript
// app/providers.tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000,
          },
        },
      })
  );
  
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

// app/todos/page.tsx
import { dehydrate, HydrationBoundary, QueryClient } from '@tanstack/react-query';

export default async function TodosPage() {
  const queryClient = new QueryClient();
  
  await queryClient.prefetchQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  });
  
  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <TodoList />
    </HydrationBoundary>
  );
}

// app/todos/todo-list.tsx
'use client';

export function TodoList() {
  // This will use the prefetched data
  const { data } = useQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  });
  
  return <ul>{data?.map(todo => <li key={todo.id}>{todo.title}</li>)}</ul>;
}
```

---

## Testing

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });
  
  return ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

test('useQuery fetches data', async () => {
  const { result } = renderHook(
    () => useQuery({ queryKey: ['test'], queryFn: () => 'data' }),
    { wrapper: createWrapper() }
  );
  
  await waitFor(() => expect(result.current.isSuccess).toBe(true));
  expect(result.current.data).toBe('data');
});

// Mock service worker for API mocking
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/todos', (req, res, ctx) => {
    return res(ctx.json([{ id: 1, title: 'Test' }]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

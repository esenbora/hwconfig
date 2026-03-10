---
name: zustand
description: Use when managing client-side state. Store creation, selectors, persistence, devtools. Triggers on: zustand, state management, store, client state, global state, useStore.
version: 1.0.0
---

# Zustand Deep Knowledge

> Middleware, persistence, subscriptions, and advanced patterns.

---

## Quick Reference

```typescript
import { create } from 'zustand';

const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}));
```

---

## Store Patterns

### Typed Store

```typescript
import { create } from 'zustand';

interface BearState {
  bears: number;
  addBear: () => void;
  setBears: (count: number) => void;
  reset: () => void;
}

const useBearStore = create<BearState>()((set) => ({
  bears: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
  setBears: (count) => set({ bears: count }),
  reset: () => set({ bears: 0 }),
}));
```

### Store with Get

```typescript
const useStore = create<Store>()((set, get) => ({
  count: 0,
  doubleCount: () => {
    const current = get().count;
    set({ count: current * 2 });
  },
  // Computed value via selector
  getDoubled: () => get().count * 2,
}));
```

### Store Slices (Modular Stores)

```typescript
import { StateCreator } from 'zustand';

// User slice
interface UserSlice {
  user: User | null;
  setUser: (user: User | null) => void;
}

const createUserSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
});

// Cart slice
interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  clearCart: () => void;
}

const createCartSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  CartSlice
> = (set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  clearCart: () => set({ items: [] }),
});

// Combined store
const useStore = create<UserSlice & CartSlice>()((...a) => ({
  ...createUserSlice(...a),
  ...createCartSlice(...a),
}));
```

---

## Middleware

### Persist Middleware

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  user: User | null;
  setAuth: (token: string, user: User) => void;
  logout: () => void;
}

const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      setAuth: (token, user) => set({ token, user }),
      logout: () => set({ token: null, user: null }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => localStorage),
      
      // Partial persistence
      partialize: (state) => ({ token: state.token, user: state.user }),
      
      // Migration between versions
      version: 1,
      migrate: (persistedState, version) => {
        if (version === 0) {
          // Migrate from version 0 to 1
          return { ...persistedState, newField: 'default' };
        }
        return persistedState;
      },
      
      // Skip hydration (for SSR)
      skipHydration: true,
    }
  )
);

// Manual hydration (for SSR)
useAuthStore.persist.rehydrate();
```

### DevTools Middleware

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

const useStore = create<State>()(
  devtools(
    (set) => ({
      count: 0,
      increment: () => set(
        (state) => ({ count: state.count + 1 }),
        false,
        'increment' // Action name in devtools
      ),
    }),
    {
      name: 'MyStore',
      enabled: process.env.NODE_ENV === 'development',
    }
  )
);
```

### Immer Middleware

```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface State {
  nested: { deeply: { value: number } };
  items: { id: number; name: string }[];
}

const useStore = create<State>()(
  immer((set) => ({
    nested: { deeply: { value: 0 } },
    items: [],
    
    // Mutate directly with immer
    updateDeepValue: (value: number) =>
      set((state) => {
        state.nested.deeply.value = value;
      }),
    
    addItem: (item) =>
      set((state) => {
        state.items.push(item);
      }),
    
    updateItem: (id: number, name: string) =>
      set((state) => {
        const item = state.items.find((i) => i.id === id);
        if (item) {
          item.name = name;
        }
      }),
  }))
);
```

### Combined Middleware

```typescript
import { create } from 'zustand';
import { devtools, persist, subscribeWithSelector } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

const useStore = create<State>()(
  devtools(
    persist(
      subscribeWithSelector(
        immer((set, get) => ({
          // Store implementation
        }))
      ),
      { name: 'store' }
    ),
    { name: 'MyStore' }
  )
);
```

---

## Subscriptions

### Subscribe to Store

```typescript
// Subscribe to entire store
const unsub = useStore.subscribe((state) => {
  console.log('State changed:', state);
});

// Subscribe with selector (requires subscribeWithSelector middleware)
const unsub = useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log('Count changed from', prevCount, 'to', count);
  },
  {
    equalityFn: Object.is,
    fireImmediately: true,
  }
);

// Cleanup
unsub();
```

### Subscribe in React

```typescript
import { useEffect } from 'react';

function Component() {
  useEffect(() => {
    const unsub = useStore.subscribe(
      (state) => state.count,
      (count) => {
        // Side effect when count changes
        analytics.track('count_changed', { count });
      }
    );
    
    return unsub;
  }, []);
}
```

---

## Selectors & Performance

### Basic Selectors

```typescript
// Bad: re-renders on ANY state change
const { bears, fish } = useStore();

// Good: only re-renders when bears changes
const bears = useStore((state) => state.bears);

// Multiple values (creates new object - always re-renders!)
const { bears, fish } = useStore((state) => ({
  bears: state.bears,
  fish: state.fish,
})); // ❌ Bad

// Use shallow equality
import { shallow } from 'zustand/shallow';

const { bears, fish } = useStore(
  (state) => ({ bears: state.bears, fish: state.fish }),
  shallow
); // ✅ Good
```

### useShallow Hook (v4.4+)

```typescript
import { useShallow } from 'zustand/react/shallow';

const { bears, fish } = useStore(
  useShallow((state) => ({ bears: state.bears, fish: state.fish }))
);
```

### Memoized Selectors

```typescript
// Define selectors outside component
const selectBears = (state: State) => state.bears;
const selectFish = (state: State) => state.fish;
const selectTotal = (state: State) => state.bears + state.fish;

// Use in component
function Component() {
  const bears = useStore(selectBears);
  const total = useStore(selectTotal);
}
```

---

## Async Actions

```typescript
interface State {
  users: User[];
  loading: boolean;
  error: string | null;
  fetchUsers: () => Promise<void>;
}

const useStore = create<State>()((set) => ({
  users: [],
  loading: false,
  error: null,
  
  fetchUsers: async () => {
    set({ loading: true, error: null });
    
    try {
      const response = await fetch('/api/users');
      const users = await response.json();
      set({ users, loading: false });
    } catch (error) {
      set({ error: error.message, loading: false });
    }
  },
}));
```

---

## Store Outside React

```typescript
// Access store outside React components
const { count, increment } = useStore.getState();

// Set state directly
useStore.setState({ count: 10 });

// Subscribe
const unsub = useStore.subscribe(console.log);

// Use in non-React code (e.g., API client)
export const apiClient = {
  get: async (url: string) => {
    const token = useAuthStore.getState().token;
    return fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
  },
};
```

---

## Testing

```typescript
import { act, renderHook } from '@testing-library/react';

// Reset store between tests
beforeEach(() => {
  useStore.setState({ count: 0 });
});

test('should increment count', () => {
  const { result } = renderHook(() => useStore());
  
  act(() => {
    result.current.increment();
  });
  
  expect(result.current.count).toBe(1);
});

test('should test async action', async () => {
  const { result } = renderHook(() => useStore());
  
  await act(async () => {
    await result.current.fetchUsers();
  });
  
  expect(result.current.users).toHaveLength(3);
});
```

---

## SSR Hydration

```typescript
// Store with skipHydration
const useStore = create<State>()(
  persist(
    (set) => ({
      // ...
    }),
    {
      name: 'store',
      skipHydration: true,
    }
  )
);

// Hydration component
function Hydration() {
  useEffect(() => {
    useStore.persist.rehydrate();
  }, []);
  
  return null;
}

// Or check hydration state
function App() {
  const [hydrated, setHydrated] = useState(false);
  
  useEffect(() => {
    const unsub = useStore.persist.onFinishHydration(() => {
      setHydrated(true);
    });
    
    useStore.persist.rehydrate();
    
    return unsub;
  }, []);
  
  if (!hydrated) {
    return <Loading />;
  }
  
  return <MainApp />;
}
```

---

## Context for Testing/SSR

```typescript
import { createContext, useContext, useRef } from 'react';
import { createStore, useStore as useZustandStore, StoreApi } from 'zustand';

// Create store factory
const createBearStore = (initial: Partial<BearState> = {}) =>
  createStore<BearState>()((set) => ({
    bears: initial.bears ?? 0,
    addBear: () => set((state) => ({ bears: state.bears + 1 })),
  }));

type BearStore = ReturnType<typeof createBearStore>;

// Context
const BearStoreContext = createContext<BearStore | null>(null);

// Provider
export function BearStoreProvider({ children, ...props }) {
  const storeRef = useRef<BearStore>();
  
  if (!storeRef.current) {
    storeRef.current = createBearStore(props);
  }
  
  return (
    <BearStoreContext.Provider value={storeRef.current}>
      {children}
    </BearStoreContext.Provider>
  );
}

// Hook
export function useBearStore<T>(selector: (state: BearState) => T): T {
  const store = useContext(BearStoreContext);
  if (!store) throw new Error('Missing BearStoreProvider');
  return useZustandStore(store, selector);
}
```

---
name: react
description: Use when building with React. Hooks, state, effects, refs, performance, components. Triggers on: react, hook, useState, useEffect, useRef, useMemo, useCallback, component, jsx, tsx.
version: 1.0.0
---

# React Deep Knowledge

> Fiber architecture, reconciliation, concurrent rendering, and performance patterns.

---

## Quick Reference

```typescript
import { useState, useEffect, useMemo, useCallback } from 'react';

function Component() {
  const [state, setState] = useState(initialValue);
  
  useEffect(() => {
    // Side effects
    return () => cleanup();
  }, [deps]);
  
  return <div>{state}</div>;
}
```

---

## Fiber Architecture

### What is Fiber?

```
Fiber = React's reconciliation engine (React 16+)

Key concepts:
- Unit of work (fiber = virtual DOM node)
- Interruptible rendering
- Priority-based scheduling
- Concurrent rendering support
```

### Fiber Node Structure

```typescript
type Fiber = {
  tag: WorkTag;           // Component type (FunctionComponent, HostComponent, etc.)
  key: null | string;     // Key for reconciliation
  type: any;              // Function/class/string (div, span)
  stateNode: any;         // DOM node or class instance
  
  // Tree structure
  return: Fiber | null;   // Parent fiber
  child: Fiber | null;    // First child
  sibling: Fiber | null;  // Next sibling
  
  // State
  pendingProps: any;      // New props
  memoizedProps: any;     // Props used in last render
  memoizedState: any;     // State used in last render
  
  // Effects
  flags: Flags;           // Side effects to perform
  subtreeFlags: Flags;    // Side effects in subtree
  
  // Lanes (priority)
  lanes: Lanes;           // Pending work priority
  childLanes: Lanes;      // Child pending work priority
};
```

### Reconciliation Algorithm

```
1. Render Phase (interruptible)
   - Build new fiber tree ("work in progress")
   - Compare with current tree (diffing)
   - Mark fibers with side effects
   
2. Commit Phase (synchronous)
   - Apply DOM mutations
   - Run layout effects
   - Run passive effects (useEffect)
```

---

## Concurrent Rendering

### Transitions

```typescript
import { useTransition, startTransition } from 'react';

function SearchResults() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [isPending, startTransition] = useTransition();
  
  const handleChange = (e) => {
    // Urgent: update input immediately
    setQuery(e.target.value);
    
    // Non-urgent: can be interrupted
    startTransition(() => {
      setResults(filterResults(e.target.value));
    });
  };
  
  return (
    <>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <ResultsList results={results} />
    </>
  );
}
```

### Deferred Values

```typescript
import { useDeferredValue } from 'react';

function SearchResults({ query }) {
  // Deferred value lags behind
  const deferredQuery = useDeferredValue(query);
  
  // Use deferred value for expensive computation
  const results = useMemo(
    () => filterResults(deferredQuery),
    [deferredQuery]
  );
  
  // Show stale content indicator
  const isStale = query !== deferredQuery;
  
  return (
    <div style={{ opacity: isStale ? 0.7 : 1 }}>
      <ResultsList results={results} />
    </div>
  );
}
```

### Suspense

```typescript
import { Suspense, lazy } from 'react';

// Code splitting
const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Skeleton />}>
      <HeavyComponent />
    </Suspense>
  );
}

// Data fetching (with React Query, SWR, or use())
function ProfilePage({ userId }) {
  return (
    <Suspense fallback={<ProfileSkeleton />}>
      <ProfileDetails userId={userId} />
    </Suspense>
  );
}
```

---

## Performance Optimization

### Memoization

```typescript
import { memo, useMemo, useCallback } from 'react';

// Memoize component
const ExpensiveComponent = memo(function ExpensiveComponent({ data, onClick }) {
  return (
    <div onClick={onClick}>
      {data.map(item => <Item key={item.id} {...item} />)}
    </div>
  );
});

// Memoize values
function ParentComponent({ items }) {
  // Memoize expensive computation
  const processedItems = useMemo(() => {
    return items.map(item => expensiveProcess(item));
  }, [items]);
  
  // Memoize callback
  const handleClick = useCallback((id) => {
    console.log('Clicked:', id);
  }, []);
  
  return <ExpensiveComponent data={processedItems} onClick={handleClick} />;
}
```

### When NOT to Memoize

```typescript
// ❌ Unnecessary memoization
const value = useMemo(() => a + b, [a, b]); // Simple calculation

// ❌ Memoizing primitive props
const Component = memo(({ count }) => <div>{count}</div>);

// ❌ New object on every render defeats memo
<MemoizedComponent config={{ theme: 'dark' }} /> // New object each render

// ✅ Stable reference
const config = useMemo(() => ({ theme: 'dark' }), []);
<MemoizedComponent config={config} />
```

### Keys and Reconciliation

```typescript
// ❌ Bad: Index as key causes issues with reordering
{items.map((item, index) => (
  <Item key={index} {...item} />
))}

// ✅ Good: Stable unique key
{items.map((item) => (
  <Item key={item.id} {...item} />
))}

// Force remount with key change
<ProfileEditor key={userId} userId={userId} />
```

### Avoid Re-renders

```typescript
// ❌ Inline object creates new reference
<Component style={{ color: 'red' }} />

// ✅ Stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Component style={style} />

// ❌ Inline function creates new reference
<Component onClick={() => handleClick(id)} />

// ✅ Stable callback
const onClick = useCallback(() => handleClick(id), [id]);
<Component onClick={onClick} />

// Or use data attributes
<Component onClick={handleClick} data-id={id} />

const handleClick = useCallback((e) => {
  const id = e.currentTarget.dataset.id;
  // ...
}, []);
```

---

## Hooks Deep Dive

### useEffect Cleanup

```typescript
useEffect(() => {
  const controller = new AbortController();
  
  fetch('/api/data', { signal: controller.signal })
    .then(res => res.json())
    .then(setData)
    .catch(err => {
      if (err.name !== 'AbortError') throw err;
    });
  
  return () => controller.abort();
}, []);

// Event listeners
useEffect(() => {
  const handler = (e) => console.log(e);
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);

// Subscriptions
useEffect(() => {
  const subscription = store.subscribe(handleChange);
  return () => subscription.unsubscribe();
}, []);
```

### useLayoutEffect vs useEffect

```typescript
// useLayoutEffect: Runs synchronously after DOM mutation
// Use for: DOM measurements, preventing flicker
useLayoutEffect(() => {
  const rect = ref.current.getBoundingClientRect();
  setPosition({ x: rect.left, y: rect.top });
}, []);

// useEffect: Runs asynchronously after paint
// Use for: Data fetching, subscriptions, logging
useEffect(() => {
  fetchData().then(setData);
}, []);
```

### Custom Hooks Patterns

```typescript
// Encapsulate complex logic
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  
  return debouncedValue;
}

// Compose hooks
function useForm<T>(initialValues: T) {
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const handleChange = useCallback((e) => {
    const { name, value } = e.target;
    setValues(prev => ({ ...prev, [name]: value }));
  }, []);
  
  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
  }, [initialValues]);
  
  return { values, errors, isSubmitting, handleChange, reset };
}
```

---

## Context Optimization

### Split Contexts

```typescript
// ❌ Single context causes all consumers to re-render
const AppContext = createContext({ user, theme, settings });

// ✅ Split by update frequency
const UserContext = createContext(null);
const ThemeContext = createContext('light');
const SettingsContext = createContext({});

// ✅ Separate state and dispatch
const StateContext = createContext(null);
const DispatchContext = createContext(null);

function Provider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);
  
  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StateContext.Provider>
  );
}

// Components that only dispatch don't re-render on state change
function ActionButton() {
  const dispatch = useContext(DispatchContext);
  return <button onClick={() => dispatch({ type: 'INCREMENT' })}>+</button>;
}
```

### Context with Selectors

```typescript
// Using use-context-selector
import { createContext, useContextSelector } from 'use-context-selector';

const Context = createContext(null);

function Consumer() {
  // Only re-renders when user.name changes
  const name = useContextSelector(Context, (v) => v.user.name);
  return <div>{name}</div>;
}
```

---

## Error Boundaries

```typescript
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };
  
  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught:', error, errorInfo);
    this.props.onError?.(error, errorInfo);
  }
  
  render() {
    if (this.state.hasError) {
      return this.props.fallback || <h1>Something went wrong.</h1>;
    }
    return this.props.children;
  }
}

// Usage
<ErrorBoundary fallback={<ErrorPage />} onError={logError}>
  <App />
</ErrorBoundary>
```

---

## Profiling

```typescript
// React DevTools Profiler
import { Profiler } from 'react';

function onRender(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number
) {
  console.log(`${id} ${phase}: ${actualDuration}ms`);
}

<Profiler id="Navigation" onRender={onRender}>
  <Navigation />
</Profiler>

// why-did-you-render library
import whyDidYouRender from '@welldone-software/why-did-you-render';

whyDidYouRender(React, {
  trackAllPureComponents: true,
});

// Mark specific component
MyComponent.whyDidYouRender = true;
```

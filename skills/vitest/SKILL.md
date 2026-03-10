---
name: vitest
description: Use when writing unit tests with Vitest. Test setup, mocking, coverage, snapshots. Triggers on: vitest, unit test, test, mock, coverage, snapshot, describe, it, expect.
version: 1.0.0
---

# Vitest Deep Knowledge

> Mocking, coverage, parallel tests, and advanced testing patterns.

---

## Quick Reference

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('MyFunction', () => {
  it('should work', () => {
    expect(myFunction()).toBe(true);
  });
});
```

---

## Configuration

### vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    // Environment
    environment: 'jsdom', // or 'node', 'happy-dom'
    
    // Globals
    globals: true, // Use describe, it, expect without import
    
    // Setup files
    setupFiles: ['./src/test/setup.ts'],
    
    // Include/exclude
    include: ['**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache'],
    
    // Coverage
    coverage: {
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'json', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.{ts,tsx}'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
    
    // Performance
    pool: 'threads', // or 'forks', 'vmThreads'
    poolOptions: {
      threads: {
        singleThread: false,
        maxThreads: 4,
        minThreads: 1,
      },
    },
    
    // Timeouts
    testTimeout: 10000,
    hookTimeout: 10000,
    
    // Reporters
    reporters: ['default', 'html'],
    outputFile: {
      html: './html-report/index.html',
    },
    
    // Watch mode
    watch: false,
    watchExclude: ['node_modules', 'dist'],
    
    // Other
    passWithNoTests: true,
    sequence: {
      shuffle: true, // Randomize test order
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### Setup File

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, beforeAll, vi } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock globals
beforeAll(() => {
  // Mock window.matchMedia
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
  
  // Mock IntersectionObserver
  const mockIntersectionObserver = vi.fn();
  mockIntersectionObserver.mockReturnValue({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  });
  window.IntersectionObserver = mockIntersectionObserver;
});
```

---

## Mocking

### Function Mocks

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';

// Create mock function
const mockFn = vi.fn();

// With implementation
const mockFn = vi.fn(() => 'default');
const mockFn = vi.fn((x: number) => x * 2);

// Mock return values
mockFn.mockReturnValue('value');
mockFn.mockReturnValueOnce('first').mockReturnValueOnce('second');

// Mock resolved/rejected values (async)
mockFn.mockResolvedValue({ data: 'test' });
mockFn.mockResolvedValueOnce({ data: 'first' });
mockFn.mockRejectedValue(new Error('Failed'));

// Mock implementation
mockFn.mockImplementation((x) => x + 1);
mockFn.mockImplementationOnce((x) => x * 2);

// Assertions
expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(3);
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
expect(mockFn).toHaveBeenLastCalledWith('lastArg');
expect(mockFn).toHaveBeenNthCalledWith(1, 'firstArg');
expect(mockFn).toHaveReturnedWith('value');

// Clear/reset
mockFn.mockClear(); // Clear call history
mockFn.mockReset(); // Clear history + implementation
mockFn.mockRestore(); // Restore original (for spies)
```

### Module Mocks

```typescript
// Mock entire module
vi.mock('./api', () => ({
  fetchUser: vi.fn(() => Promise.resolve({ id: 1, name: 'Test' })),
  fetchPosts: vi.fn(() => Promise.resolve([])),
}));

// Mock with factory
vi.mock('./utils', () => {
  return {
    formatDate: vi.fn((date) => '2024-01-01'),
    calculateTotal: vi.fn((items) => 100),
  };
});

// Partial mock (keep some real implementations)
vi.mock('./utils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./utils')>();
  return {
    ...actual,
    formatDate: vi.fn(() => 'mocked-date'),
  };
});

// Access mocked module
import { fetchUser } from './api';

vi.mocked(fetchUser).mockResolvedValue({ id: 2, name: 'Mocked' });
```

### Spy on Object Methods

```typescript
import { vi, describe, it, expect } from 'vitest';

const object = {
  method: (x: number) => x * 2,
};

// Spy without changing implementation
const spy = vi.spyOn(object, 'method');

object.method(5);
expect(spy).toHaveBeenCalledWith(5);

// Spy with mock implementation
vi.spyOn(object, 'method').mockImplementation((x) => x + 10);

// Spy on prototype
vi.spyOn(Array.prototype, 'push');

// Restore
spy.mockRestore();
```

### Mock Timers

```typescript
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('Timers', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });
  
  afterEach(() => {
    vi.useRealTimers();
  });
  
  it('should handle setTimeout', () => {
    const callback = vi.fn();
    setTimeout(callback, 1000);
    
    expect(callback).not.toHaveBeenCalled();
    
    vi.advanceTimersByTime(1000);
    expect(callback).toHaveBeenCalled();
  });
  
  it('should handle setInterval', () => {
    const callback = vi.fn();
    setInterval(callback, 500);
    
    vi.advanceTimersByTime(1500);
    expect(callback).toHaveBeenCalledTimes(3);
  });
  
  it('should run all timers', async () => {
    const callback = vi.fn();
    setTimeout(callback, 5000);
    
    vi.runAllTimers();
    expect(callback).toHaveBeenCalled();
  });
  
  it('should handle async timers', async () => {
    const callback = vi.fn();
    setTimeout(async () => {
      await Promise.resolve();
      callback();
    }, 1000);
    
    await vi.advanceTimersByTimeAsync(1000);
    expect(callback).toHaveBeenCalled();
  });
  
  it('should mock Date', () => {
    vi.setSystemTime(new Date('2024-01-01'));
    expect(new Date().toISOString()).toContain('2024-01-01');
  });
});
```

---

## Testing React Components

### Component Testing

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { Counter } from './Counter';

describe('Counter', () => {
  it('should render initial count', () => {
    render(<Counter initialCount={5} />);
    expect(screen.getByText('Count: 5')).toBeInTheDocument();
  });
  
  it('should increment on click', async () => {
    const user = userEvent.setup();
    render(<Counter initialCount={0} />);
    
    await user.click(screen.getByRole('button', { name: /increment/i }));
    
    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });
  
  it('should call onChange when count changes', async () => {
    const onChange = vi.fn();
    const user = userEvent.setup();
    
    render(<Counter initialCount={0} onChange={onChange} />);
    
    await user.click(screen.getByRole('button', { name: /increment/i }));
    
    expect(onChange).toHaveBeenCalledWith(1);
  });
});
```

### Testing Hooks

```typescript
import { renderHook, act, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });
  
  it('should initialize with custom value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });
  
  it('should increment', () => {
    const { result } = renderHook(() => useCounter());
    
    act(() => {
      result.current.increment();
    });
    
    expect(result.current.count).toBe(1);
  });
  
  it('should handle async operations', async () => {
    const { result } = renderHook(() => useAsyncData());
    
    expect(result.current.loading).toBe(true);
    
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    
    expect(result.current.data).toBeDefined();
  });
});
```

### Testing with Context

```typescript
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ThemeProvider } from './ThemeContext';
import { ThemedButton } from './ThemedButton';

const renderWithProviders = (ui: React.ReactElement, options = {}) => {
  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <ThemeProvider theme="dark">{children}</ThemeProvider>
  );
  
  return render(ui, { wrapper: Wrapper, ...options });
};

describe('ThemedButton', () => {
  it('should use theme from context', () => {
    renderWithProviders(<ThemedButton>Click me</ThemedButton>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('dark-theme');
  });
});
```

---

## Async Testing

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Async', () => {
  // Using async/await
  it('should resolve async value', async () => {
    const result = await fetchData();
    expect(result).toBe('data');
  });
  
  // Using promises
  it('should resolve promise', () => {
    return fetchData().then((result) => {
      expect(result).toBe('data');
    });
  });
  
  // Testing rejection
  it('should reject with error', async () => {
    await expect(failingFetch()).rejects.toThrow('Error');
  });
  
  // Wait for condition
  it('should wait for element', async () => {
    render(<AsyncComponent />);
    
    const element = await screen.findByText('Loaded');
    expect(element).toBeInTheDocument();
  });
  
  // Custom timeout
  it('should complete within timeout', async () => {
    await expect(slowFetch()).resolves.toBe('done');
  }, 10000); // 10 second timeout
});
```

---

## Snapshot Testing

```typescript
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('should match snapshot', () => {
    const { container } = render(<Button>Click me</Button>);
    expect(container).toMatchSnapshot();
  });
  
  it('should match inline snapshot', () => {
    const { container } = render(<Button variant="primary">Click</Button>);
    expect(container.innerHTML).toMatchInlineSnapshot(`
      "<button class=\\"btn btn-primary\\">Click</button>"
    `);
  });
});

// Update snapshots: vitest -u
```

---

## Test Organization

### Describe Blocks

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', () => {});
    it('should throw on invalid email', () => {});
    it('should hash password', () => {});
  });
  
  describe('updateUser', () => {
    it('should update existing user', () => {});
    it('should throw on non-existent user', () => {});
  });
});
```

### Lifecycle Hooks

```typescript
import { describe, it, beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

describe('Database Tests', () => {
  beforeAll(async () => {
    // Run once before all tests
    await db.connect();
  });
  
  afterAll(async () => {
    // Run once after all tests
    await db.disconnect();
  });
  
  beforeEach(async () => {
    // Run before each test
    await db.seed();
  });
  
  afterEach(async () => {
    // Run after each test
    await db.clean();
  });
  
  it('should query database', async () => {
    const users = await db.query('SELECT * FROM users');
    expect(users).toHaveLength(3);
  });
});
```

### Test Modifiers

```typescript
// Skip test
it.skip('should be skipped', () => {});

// Only run this test
it.only('should only run this', () => {});

// Todo test
it.todo('should implement later');

// Concurrent tests
it.concurrent('should run in parallel', async () => {});

// Retry flaky tests
it('flaky test', { retry: 3 }, () => {});

// Custom timeout
it('slow test', { timeout: 30000 }, async () => {});
```

---

## Running Tests

```bash
# Run all tests
vitest

# Run in watch mode
vitest --watch

# Run specific file
vitest src/utils.test.ts

# Run tests matching pattern
vitest --filter "UserService"

# Run with coverage
vitest --coverage

# Run single test
vitest --run

# Update snapshots
vitest -u

# Run in CI
vitest run --reporter=junit --outputFile=./test-results.xml
```

---
name: test
description: Use when writing or running tests. Unit tests, integration tests, test coverage. Triggers on: test, testing, unit test, write test, test coverage, jest, vitest, testing library.
argument-hint: "<file-or-feature-to-test>"
version: 1.0.0
context: fork
agent: tdd-guide
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
---


## Usage

```
/test <function/component>   # Write tests using TDD
/test plan                   # Generate test plan for project
/test plan <module>          # Generate test plan for module
/test run                    # Run all tests
/test run <pattern>          # Run tests matching pattern
```

---

## TDD Workflow (Default)

### RED → GREEN → REFACTOR → COMMIT

1. **RED**: Write failing test first
2. **GREEN**: Write MINIMAL code to pass
3. **REFACTOR**: Clean up (tests still pass)
4. **COMMIT**: Save progress

### Test Structure (AAA Pattern)

```typescript
it('should do something', async () => {
  // ARRANGE - Setup
  const input = { name: 'Test' }
  vi.mocked(db.user.create).mockResolvedValue({ id: '1', ...input })

  // ACT - Execute
  const result = await createUser(input)

  // ASSERT - Verify
  expect(result).toEqual({ id: '1', name: 'Test' })
})
```

### Test Categories

| Priority | Category | Examples |
|----------|----------|----------|
| P0 | Happy path | Normal operation |
| P0 | Auth | Unauthorized, forbidden |
| P1 | Validation | Invalid input |
| P1 | Edge cases | null, empty, limits |
| P2 | Error handling | DB fails, network errors |

---

## Plan Mode (`/test plan`)

Generate comprehensive test plan:

1. Analyze codebase structure
2. Check current coverage
3. Identify gaps
4. Create prioritized test list

### Output

```markdown
## Test Plan: [Project]

### Coverage Status
| Metric | Current | Target |
|--------|---------|--------|
| Statements | 65% | 80% |
| Branches | 58% | 80% |
| Functions | 70% | 80% |

### Priority Queue
1. Critical: Auth flows
2. High: API endpoints
3. Medium: Utility functions
4. Low: UI components
```

---

## Run Mode (`/test run`)

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific file
npm test -- auth.test.ts

# Run matching pattern
npm test -- --grep "login"

# Watch mode
npm test -- --watch
```

---

## Quick Reference

### Vitest Matchers
```typescript
expect(x).toBe(exact)
expect(x).toEqual(deep)
expect(x).toBeTruthy()
expect(x).toBeNull()
expect(arr).toContain(item)
expect(fn).toThrow()
await expect(promise).resolves.toBe(value)
await expect(promise).rejects.toThrow()
```

### Mock Functions
```typescript
const mock = vi.fn()
mock.mockReturnValue(value)
mock.mockResolvedValue(value)
mock.mockRejectedValue(error)
expect(mock).toHaveBeenCalledWith(args)
```

### Testing Library
```typescript
screen.getByRole('button', { name: /submit/i })
screen.getByLabelText(/email/i)
screen.getByText(/welcome/i)
await user.click(element)
await user.type(input, 'text')
```

---

## Agent: tdd-guide

The tdd-guide agent is automatically suggested for test tasks.

---

## MOBILE PLATFORM

### Mobile Test Pyramid

```
┌─────────────────────────────────────────────────────────────┐
│             E2E Tests (Maestro/Detox)                       │
│          ─────────────────────────────────                  │
│            Component Tests (RNTL)                           │
│         ────────────────────────────────────                │
│              Unit Tests (Jest/Vitest)                       │
│    ──────────────────────────────────────────────           │
└─────────────────────────────────────────────────────────────┘
```

### React Native Testing Library

#### Hook Testing

```typescript
import { renderHook, act } from '@testing-library/react-native'
import { useAuth } from '@/lib/hooks/useAuth'

describe('useAuth', () => {
  it('starts logged out', () => {
    const { result } = renderHook(() => useAuth())
    expect(result.current.isLoggedIn).toBe(false)
  })

  it('logs in user', async () => {
    const { result } = renderHook(() => useAuth())
    await act(async () => {
      await result.current.login('email@test.com', 'password')
    })
    expect(result.current.isLoggedIn).toBe(true)
  })
})
```

#### Screen Testing

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react-native'
import HomeScreen from '@/app/(tabs)/index'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const wrapper = ({ children }) => (
  <QueryClientProvider client={new QueryClient()}>
    {children}
  </QueryClientProvider>
)

describe('HomeScreen', () => {
  it('shows loading initially', () => {
    render(<HomeScreen />, { wrapper })
    expect(screen.getByTestId('loading')).toBeTruthy()
  })

  it('displays items after loading', async () => {
    render(<HomeScreen />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('Item 1')).toBeTruthy()
    })
  })

  it('handles item press', async () => {
    const onPress = jest.fn()
    render(<HomeScreen onItemPress={onPress} />, { wrapper })
    await waitFor(() => screen.getByText('Item 1'))
    fireEvent.press(screen.getByText('Item 1'))
    expect(onPress).toHaveBeenCalled()
  })
})
```

#### Form Testing

```typescript
import { render, fireEvent, waitFor } from '@testing-library/react-native'
import { LoginForm } from '@/components/LoginForm'

describe('LoginForm', () => {
  it('validates email', async () => {
    const { getByPlaceholderText, getByText, queryByText } = render(<LoginForm />)

    fireEvent.changeText(getByPlaceholderText('Email'), 'invalid')
    fireEvent.press(getByText('Login'))

    await waitFor(() => {
      expect(queryByText('Invalid email')).toBeTruthy()
    })
  })

  it('submits valid form', async () => {
    const onSubmit = jest.fn()
    const { getByPlaceholderText, getByText } = render(
      <LoginForm onSubmit={onSubmit} />
    )

    fireEvent.changeText(getByPlaceholderText('Email'), 'test@email.com')
    fireEvent.changeText(getByPlaceholderText('Password'), 'password123')
    fireEvent.press(getByText('Login'))

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'test@email.com',
        password: 'password123',
      })
    })
  })
})
```

### E2E Tests with Maestro

#### Maestro Flow

```yaml
# .maestro/login-flow.yaml
appId: com.yourapp.app
---
- launchApp
- tapOn: "Sign In"
- tapOn:
    id: "email-input"
- inputText: "test@example.com"
- tapOn:
    id: "password-input"
- inputText: "password123"
- tapOn: "Submit"
- assertVisible: "Welcome"
```

#### Run Maestro

```bash
# Install
curl -Ls "https://get.maestro.mobile.dev" | bash

# Run single test
maestro test .maestro/login-flow.yaml

# Run all tests
maestro test .maestro/
```

### E2E Tests with Detox

```typescript
// e2e/login.test.ts
describe('Login Flow', () => {
  beforeAll(async () => {
    await device.launchApp()
  })

  it('should login successfully', async () => {
    await element(by.id('email-input')).typeText('test@example.com')
    await element(by.id('password-input')).typeText('password123')
    await element(by.id('login-button')).tap()
    await expect(element(by.text('Welcome'))).toBeVisible()
  })
})
```

### Accessibility Tests

```typescript
import { render } from '@testing-library/react-native'

describe('Accessibility', () => {
  it('has accessible labels', () => {
    const { getByA11yLabel } = render(<Button label="Submit" />)
    expect(getByA11yLabel('Submit button')).toBeTruthy()
  })

  it('has proper roles', () => {
    const { getByRole } = render(<Button label="Submit" />)
    expect(getByRole('button')).toBeTruthy()
  })
})
```

### Platform-Specific Tests

```typescript
import { Platform } from 'react-native'

describe('Platform behavior', () => {
  it('handles iOS-specific behavior', () => {
    Platform.OS = 'ios'
    // Test iOS-specific code
  })

  it('handles Android-specific behavior', () => {
    Platform.OS = 'android'
    // Test Android-specific code
  })
})
```

### Mobile Test Output

```markdown
## Tests Written

**For:** [Component/Feature]

### Coverage
- Unit tests: [X]
- Component tests: [X]
- E2E tests: [X]

### Test Files
- [file]: [what's tested]

### Run Results
- All tests pass: Yes/No
- Coverage: [X]%

### Platform Verification
- [ ] Tests pass on iOS
- [ ] Tests pass on Android
```

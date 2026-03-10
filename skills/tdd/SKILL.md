---
name: tdd
description: Use when writing tests or implementing features. Test-driven development - write test first. Triggers on: tdd, test driven, test first, write test, failing test, red green refactor.
version: 1.0.0
tier: 1
---

# Test-Driven Development

**Core principle:** Write the test FIRST. Watch it fail. Then write minimal code to make it pass.

## The TDD Cycle

```
RED → GREEN → REFACTOR → COMMIT
```

1. **RED**: Write a failing test
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Clean up (tests still pass)
4. **COMMIT**: Save your work

## The Rules

### Rule 1: No Production Code Without a Failing Test

```typescript
// ❌ WRONG: Writing code first
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// ✅ RIGHT: Test first
test('calculates total of item prices', () => {
  const items = [{ price: 10 }, { price: 20 }]
  expect(calculateTotal(items)).toBe(30)
})
// Now write the function to make it pass
```

### Rule 2: Write Minimal Test to Fail

Don't write a complex test. Write the simplest test that fails.

```typescript
// ❌ TOO MUCH: Testing everything at once
test('user registration with validation and email', () => {
  // 50 lines of test...
})

// ✅ MINIMAL: One thing at a time
test('creates user with email', () => {
  const user = createUser({ email: 'test@example.com' })
  expect(user.email).toBe('test@example.com')
})
```

### Rule 3: Write Minimal Code to Pass

Don't anticipate future needs. Make the current test pass.

```typescript
// Test
test('returns greeting', () => {
  expect(greet('Alice')).toBe('Hello, Alice!')
})

// ❌ OVER-ENGINEERING
function greet(name, language = 'en', formal = false) {
  const greetings = { en: 'Hello', es: 'Hola', fr: 'Bonjour' }
  // ... 20 more lines
}

// ✅ MINIMAL
function greet(name) {
  return `Hello, ${name}!`
}
```

### Rule 4: Refactor Only When Green

Never refactor with failing tests. Get to green first.

```
Tests failing? → Fix the code (not refactor)
Tests passing? → Now you can refactor
```

## Testing Patterns

### Arrange-Act-Assert

```typescript
test('adds item to cart', () => {
  // Arrange
  const cart = new Cart()
  const item = { id: '1', price: 100 }

  // Act
  cart.addItem(item)

  // Assert
  expect(cart.items).toContain(item)
  expect(cart.total).toBe(100)
})
```

### Test Edge Cases

```typescript
describe('calculateTotal', () => {
  test('returns 0 for empty array', () => {
    expect(calculateTotal([])).toBe(0)
  })

  test('handles single item', () => {
    expect(calculateTotal([{ price: 50 }])).toBe(50)
  })

  test('handles multiple items', () => {
    expect(calculateTotal([{ price: 10 }, { price: 20 }])).toBe(30)
  })
})
```

## Anti-Patterns to Avoid

### 1. Testing Implementation, Not Behavior

```typescript
// ❌ WRONG: Testing how it works
test('uses reduce method', () => {
  const spy = jest.spyOn(Array.prototype, 'reduce')
  calculateTotal([])
  expect(spy).toHaveBeenCalled()
})

// ✅ RIGHT: Testing what it does
test('calculates total', () => {
  expect(calculateTotal([{ price: 10 }])).toBe(10)
})
```

### 2. Brittle Tests

```typescript
// ❌ BRITTLE: Depends on exact structure
expect(result).toEqual({
  id: '123',
  createdAt: '2024-01-01T00:00:00Z',
  // ... 20 fields
})

// ✅ RESILIENT: Tests what matters
expect(result.id).toBe('123')
expect(result.status).toBe('active')
```

### 3. Skipping Tests

```typescript
// ❌ NEVER: Skipping tests
test.skip('this is broken', () => {})

// ✅ ALWAYS: Fix or delete
```

## Commit Pattern

```bash
# After each RED-GREEN-REFACTOR cycle
git add .
git commit -m "test: add test for X"

# Or combined
git commit -m "feat: implement X with tests"
```

## Quick Reference

| Step | Action | Verification |
|------|--------|--------------|
| RED | Write failing test | Test fails as expected |
| GREEN | Write minimal code | Test passes |
| REFACTOR | Clean up code | Tests still pass |
| COMMIT | Save progress | Changes committed |

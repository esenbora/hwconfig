---
name: playwright
description: Use when writing end-to-end tests, browser tests, or integration tests. Page objects, fixtures, assertions. Triggers on: playwright, e2e, end to end, browser test, integration test, test automation, testing.
version: 1.0.0
detect: ["@playwright/test"]
---

# Playwright

End-to-end testing for web applications.

## Setup

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

## Basic Test

```typescript
// tests/e2e/home.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Home Page', () => {
  test('should display welcome message', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible()
  })

  test('should navigate to about page', async ({ page }) => {
    await page.goto('/')
    await page.click('text=About')
    await expect(page).toHaveURL('/about')
  })
})
```

## Authentication

```typescript
// tests/e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test'

const authFile = 'playwright/.auth/user.json'

setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('test@example.com')
  await page.getByLabel('Password').fill('password123')
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page.getByText('Dashboard')).toBeVisible()

  await page.context().storageState({ path: authFile })
})

// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
})
```

## Page Object Model

```typescript
// tests/e2e/pages/login.page.ts
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  private readonly emailInput: Locator
  private readonly passwordInput: Locator
  private readonly submitButton: Locator
  private readonly errorMessage: Locator

  constructor(private readonly page: Page) {
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password')
    this.submitButton = page.getByRole('button', { name: 'Sign in' })
    this.errorMessage = page.getByRole('alert')
  }

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }

  async getError() {
    return this.errorMessage.textContent()
  }
}

// Usage
import { LoginPage } from './pages/login.page'

test('should show error for invalid credentials', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('invalid@email.com', 'wrong')
  expect(await loginPage.getError()).toContain('Invalid credentials')
})
```

## Form Testing

```typescript
test('should submit contact form', async ({ page }) => {
  await page.goto('/contact')

  await page.getByLabel('Name').fill('John Doe')
  await page.getByLabel('Email').fill('john@example.com')
  await page.getByLabel('Message').fill('Hello, this is a test message.')

  await page.getByRole('button', { name: 'Send' }).click()

  await expect(page.getByText('Message sent successfully')).toBeVisible()
})

test('should show validation errors', async ({ page }) => {
  await page.goto('/contact')

  await page.getByRole('button', { name: 'Send' }).click()

  await expect(page.getByText('Name is required')).toBeVisible()
  await expect(page.getByText('Email is required')).toBeVisible()
})
```

## API Mocking

```typescript
test('should display mocked data', async ({ page }) => {
  await page.route('**/api/users', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' },
      ]),
    })
  })

  await page.goto('/users')

  await expect(page.getByText('John')).toBeVisible()
  await expect(page.getByText('Jane')).toBeVisible()
})
```

## Visual Regression

```typescript
test('should match screenshot', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png')
})

test('should match component screenshot', async ({ page }) => {
  await page.goto('/components')
  const button = page.getByRole('button', { name: 'Primary' })
  await expect(button).toHaveScreenshot('primary-button.png')
})
```

## Network Waiting

```typescript
test('should wait for API response', async ({ page }) => {
  // Wait for specific request
  const responsePromise = page.waitForResponse('**/api/data')
  await page.getByRole('button', { name: 'Load' }).click()
  const response = await responsePromise
  expect(response.status()).toBe(200)
})

test('should handle slow network', async ({ page }) => {
  // Slow down network
  await page.route('**/*', (route) => {
    setTimeout(() => route.continue(), 1000)
  })

  await page.goto('/')
  // Test loading states
})
```

## Running Tests

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test home.spec.ts

# Run in UI mode
npx playwright test --ui

# Run headed
npx playwright test --headed

# Debug mode
npx playwright test --debug

# Generate tests
npx playwright codegen localhost:3000
```

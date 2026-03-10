---
name: load-testing
description: Use when testing application performance under load. k6, Artillery, stress testing, performance benchmarks. Triggers on: load test, stress test, performance test, benchmark, concurrent users, throughput.
version: 1.0.0
---

# Load Testing

> Know your limits before your users find them.

---

## Quick Reference

```bash
# k6 (recommended)
k6 run script.js
k6 run --vus 100 --duration 30s script.js

# Artillery
artillery run scenario.yml
artillery quick --count 100 -n 10 http://localhost:3000/api/health

# Apache Bench (quick test)
ab -n 1000 -c 100 http://localhost:3000/api/health

# wrk (high performance)
wrk -t12 -c400 -d30s http://localhost:3000/api/health
```

---

## k6 Load Testing

### Basic Script

```javascript
// load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up
    { duration: '1m', target: 20 },   // Stay at 20
    { duration: '30s', target: 50 },  // Ramp to 50
    { duration: '1m', target: 50 },   // Stay at 50
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // <1% errors
  },
}

export default function () {
  const res = http.get('http://localhost:3000/api/health')

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  })

  sleep(1)
}
```

### API Endpoint Testing

```javascript
// api-load-test.js
import http from 'k6/http'
import { check, group, sleep } from 'k6'

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000'

export const options = {
  scenarios: {
    average_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },
        { duration: '5m', target: 50 },
        { duration: '2m', target: 0 },
      ],
    },
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 200 },
        { duration: '1m', target: 200 },
        { duration: '10s', target: 0 },
      ],
      startTime: '10m',
    },
  },
}

export default function () {
  group('API Endpoints', () => {
    // Health check
    const health = http.get(`${BASE_URL}/api/health`)
    check(health, { 'health check OK': (r) => r.status === 200 })

    // Authenticated endpoint
    const authHeaders = {
      headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
    }

    const profile = http.get(`${BASE_URL}/api/user/profile`, authHeaders)
    check(profile, { 'profile loaded': (r) => r.status === 200 })

    // POST with payload
    const payload = JSON.stringify({ query: 'test' })
    const search = http.post(`${BASE_URL}/api/search`, payload, {
      headers: { 'Content-Type': 'application/json' },
    })
    check(search, { 'search successful': (r) => r.status === 200 })
  })

  sleep(1)
}
```

### Database Load Test

```javascript
// db-load-test.js
import http from 'k6/http'
import { check } from 'k6'
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js'

export const options = {
  vus: 50,
  duration: '5m',
  thresholds: {
    http_req_duration: ['p(99)<1000'],
    'http_req_duration{type:read}': ['p(95)<200'],
    'http_req_duration{type:write}': ['p(95)<500'],
  },
}

export default function () {
  // Read operation (80% of traffic)
  if (Math.random() < 0.8) {
    const id = randomIntBetween(1, 10000)
    const res = http.get(`${BASE_URL}/api/items/${id}`, {
      tags: { type: 'read' },
    })
    check(res, { 'item found': (r) => r.status === 200 || r.status === 404 })
  }
  // Write operation (20% of traffic)
  else {
    const payload = JSON.stringify({
      name: randomString(10),
      value: randomIntBetween(1, 100),
    })
    const res = http.post(`${BASE_URL}/api/items`, payload, {
      headers: { 'Content-Type': 'application/json' },
      tags: { type: 'write' },
    })
    check(res, { 'item created': (r) => r.status === 201 })
  }
}
```

---

## Artillery (YAML-based)

### Basic Scenario

```yaml
# artillery.yml
config:
  target: "http://localhost:3000"
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 10
      name: "Sustained load"
    - duration: 60
      arrivalRate: 50
      name: "Spike"

scenarios:
  - name: "Browse and search"
    flow:
      - get:
          url: "/"
      - think: 1
      - get:
          url: "/api/products"
          capture:
            - json: "$[0].id"
              as: "productId"
      - get:
          url: "/api/products/{{ productId }}"
```

### With Authentication

```yaml
config:
  target: "http://localhost:3000"
  phases:
    - duration: 300
      arrivalRate: 20
  payload:
    path: "users.csv"
    fields:
      - "email"
      - "password"

scenarios:
  - name: "Authenticated user journey"
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "{{ email }}"
            password: "{{ password }}"
          capture:
            - json: "$.token"
              as: "authToken"
      - get:
          url: "/api/dashboard"
          headers:
            Authorization: "Bearer {{ authToken }}"
```

---

## Performance Thresholds

### Target Metrics by Type

| Metric | Target | Critical |
|--------|--------|----------|
| **API Response (p95)** | < 200ms | > 1s |
| **Page Load (p95)** | < 2s | > 5s |
| **Database Query** | < 50ms | > 200ms |
| **Error Rate** | < 0.1% | > 1% |
| **Throughput** | > 1000 rps | < 100 rps |

### Apdex Score

```
Apdex = (Satisfied + Tolerating/2) / Total

Satisfied: < T (e.g., 500ms)
Tolerating: T to 4T (500ms-2s)
Frustrated: > 4T (> 2s)

Target Apdex: > 0.9
```

---

## Common Test Types

### 1. Smoke Test
Quick validation that system works under minimal load.

```javascript
export const options = {
  vus: 1,
  duration: '1m',
}
```

### 2. Load Test
Normal and peak load testing.

```javascript
export const options = {
  stages: [
    { duration: '5m', target: 100 },
    { duration: '10m', target: 100 },
    { duration: '5m', target: 0 },
  ],
}
```

### 3. Stress Test
Find breaking point.

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '5m', target: 300 },
    { duration: '2m', target: 0 },
  ],
}
```

### 4. Spike Test
Sudden traffic surge.

```javascript
export const options = {
  stages: [
    { duration: '10s', target: 100 },
    { duration: '1m', target: 100 },
    { duration: '10s', target: 1000 },
    { duration: '3m', target: 1000 },
    { duration: '10s', target: 100 },
    { duration: '3m', target: 100 },
    { duration: '10s', target: 0 },
  ],
}
```

### 5. Soak Test
Extended duration to find memory leaks.

```javascript
export const options = {
  stages: [
    { duration: '5m', target: 100 },
    { duration: '4h', target: 100 },
    { duration: '5m', target: 0 },
  ],
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Load Test

on:
  schedule:
    - cron: '0 2 * * *'  # Nightly
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install k6
        run: |
          curl -s https://dl.k6.io/key.gpg | sudo apt-key add -
          echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update
          sudo apt-get install k6

      - name: Run load test
        run: k6 run --out json=results.json tests/load/api.js
        env:
          BASE_URL: ${{ secrets.STAGING_URL }}

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: load-test-results
          path: results.json
```

---

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Test production without warning | Use staging or dedicated test env |
| No baseline measurements | Establish baseline first |
| Ignore ramp-up period | Gradual load increase |
| Test single endpoint only | Test realistic user journeys |
| Fixed VUs only | Use scenarios with stages |
| Skip error analysis | Investigate all failures |

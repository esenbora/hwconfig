---
name: dependency-security
description: Use when adding packages, updating dependencies, or checking for vulnerabilities. Supply chain security. Triggers on: dependency, npm audit, vulnerability, package, outdated, security advisory, supply chain.
version: 1.0.0
detect: ["security-audit"]
---

# Dependency & Supply Chain Security

Patterns for managing dependency vulnerabilities and supply chain risks.

## Vulnerability Scanning

### npm audit

```bash
# Basic audit
npm audit

# JSON output for parsing
npm audit --json

# Fix automatically where possible
npm audit fix

# Force fix (may include breaking changes)
npm audit fix --force

# Only production dependencies
npm audit --omit=dev
```

### Automated Scanning

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * *' # Daily

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run npm audit
        run: npm audit --audit-level=high
        
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## Lock File Security

### Verify Lock File Integrity

```typescript
// scripts/verify-lockfile.ts
import crypto from 'crypto'
import fs from 'fs'

// ✅ Verify package-lock.json hasn't been tampered with
function verifyLockfile() {
  const lockfile = fs.readFileSync('package-lock.json', 'utf-8')
  const parsed = JSON.parse(lockfile)
  
  // Check for suspicious patterns
  const suspicious = []
  
  function checkPackage(name: string, pkg: any) {
    // Check for unexpected registry
    if (pkg.resolved && !pkg.resolved.includes('registry.npmjs.org')) {
      suspicious.push(`${name}: Unexpected registry - ${pkg.resolved}`)
    }
    
    // Check for git URLs (potential supply chain attack)
    if (pkg.resolved?.includes('git+') || pkg.resolved?.includes('github.com')) {
      suspicious.push(`${name}: Git dependency - ${pkg.resolved}`)
    }
    
    // Check for local file dependencies
    if (pkg.resolved?.startsWith('file:')) {
      suspicious.push(`${name}: Local file dependency - ${pkg.resolved}`)
    }
  }
  
  // Recursively check all packages
  function walkPackages(packages: Record<string, any>, prefix = '') {
    for (const [name, pkg] of Object.entries(packages)) {
      checkPackage(prefix + name, pkg)
      if (pkg.dependencies) {
        walkPackages(pkg.dependencies, prefix + name + '/')
      }
    }
  }
  
  if (parsed.packages) {
    walkPackages(parsed.packages)
  }
  
  if (suspicious.length > 0) {
    console.error('Suspicious dependencies found:')
    suspicious.forEach(s => console.error(`  - ${s}`))
    process.exit(1)
  }
  
  console.log('Lock file verification passed')
}

verifyLockfile()
```

### Lock File Best Practices

```bash
# ✅ Always commit lock files
git add package-lock.json

# ✅ Use npm ci in CI/CD (respects lock file exactly)
npm ci

# ❌ Don't use npm install in CI (may update lock file)
npm install
```

## Dependency Pinning

### Exact Versions

```json
// package.json
{
  "dependencies": {
    // ✅ Exact version - most secure
    "lodash": "4.17.21",
    
    // ⚠️ Minor updates - moderate risk
    "react": "^18.2.0",
    
    // ❌ Major updates - high risk
    "some-lib": "*"
  }
}
```

### Renovate/Dependabot Configuration

```json
// renovate.json
{
  "extends": ["config:base"],
  "schedule": ["before 9am on monday"],
  "labels": ["dependencies"],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "schedule": ["at any time"]
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "labels": ["major-update"],
      "reviewers": ["team:security"]
    },
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true,
      "automergeType": "branch"
    }
  ]
}
```

## Known Vulnerable Packages

```typescript
// ✅ Check for known vulnerable packages
const KNOWN_VULNERABLE = [
  'event-stream', // Malicious code injection (2018)
  'flatmap-stream', // Part of event-stream attack
  'ua-parser-js', // Malicious code (2021)
  'coa', // Malicious code (2021)
  'rc', // Malicious code (2021)
]

function checkKnownVulnerable(packageJson: any) {
  const allDeps = {
    ...packageJson.dependencies,
    ...packageJson.devDependencies,
  }
  
  const found = KNOWN_VULNERABLE.filter(pkg => pkg in allDeps)
  
  if (found.length > 0) {
    console.error('Known vulnerable packages found:')
    found.forEach(pkg => console.error(`  - ${pkg}`))
    return false
  }
  
  return true
}
```

## License Compliance

```typescript
// ✅ Check for problematic licenses
const PROBLEMATIC_LICENSES = [
  'GPL-3.0',
  'AGPL-3.0',
  'SSPL',
  'Commons Clause',
]

async function checkLicenses() {
  // Use license-checker
  const checker = require('license-checker')
  
  return new Promise((resolve, reject) => {
    checker.init({ start: './' }, (err: Error, packages: Record<string, any>) => {
      if (err) return reject(err)
      
      const issues = []
      
      for (const [pkg, info] of Object.entries(packages)) {
        if (PROBLEMATIC_LICENSES.some(l => info.licenses?.includes(l))) {
          issues.push(`${pkg}: ${info.licenses}`)
        }
      }
      
      resolve(issues)
    })
  })
}
```

## Runtime Integrity

```typescript
// ✅ Verify package integrity at runtime (for critical packages)
import crypto from 'crypto'
import fs from 'fs'

const EXPECTED_HASHES = {
  'stripe': 'sha512-abc123...',
  // Add hashes for critical dependencies
}

function verifyPackageIntegrity(packageName: string) {
  const packagePath = require.resolve(packageName)
  const content = fs.readFileSync(packagePath)
  const hash = crypto.createHash('sha512').update(content).digest('base64')
  
  if (EXPECTED_HASHES[packageName] !== `sha512-${hash}`) {
    throw new Error(`Package integrity check failed: ${packageName}`)
  }
}
```

## Subresource Integrity (SRI)

```html
<!-- ✅ Use SRI for external scripts -->
<script 
  src="https://cdn.example.com/lib.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
  crossorigin="anonymous">
</script>

<!-- Generate SRI hash -->
<!-- openssl dgst -sha384 -binary lib.js | openssl base64 -A -->
```

## Audit Checklist

```markdown
## Dependency Security Audit

### Critical
- [ ] No known critical vulnerabilities (npm audit)
- [ ] Lock file committed and used in CI
- [ ] No dependencies from untrusted sources

### High
- [ ] Automated vulnerability scanning in CI
- [ ] Dependencies updated regularly
- [ ] Git dependencies avoided

### Medium
- [ ] Exact versions for critical packages
- [ ] License compliance verified
- [ ] Dependabot/Renovate configured

### Low
- [ ] Unused dependencies removed
- [ ] Bundle size analyzed
- [ ] Alternative packages evaluated for security
```

## Response Plan

```markdown
## Vulnerability Response Plan

### When Critical Vulnerability Found

1. **Assess Impact**
   - Is the vulnerable code path used?
   - Is it exploitable in our context?
   - What data/systems are at risk?

2. **Immediate Actions**
   - If exploitable: Take service offline or implement WAF rule
   - Check for signs of exploitation
   - Notify security team

3. **Remediation**
   - Update to patched version
   - If no patch: Find alternative or implement workaround
   - Test thoroughly before deploying

4. **Post-Incident**
   - Document incident and response
   - Update monitoring/alerts
   - Review detection capabilities
```

---
name: refactor
description: Use when cleaning up, reorganizing, or improving existing code without changing behavior. Safe refactoring patterns. Triggers on: refactor, clean up, reorganize, restructure, improve code, technical debt, simplify.
argument-hint: "<file-or-area-to-refactor>"
version: 1.0.0
context: fork
agent: quality
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
---


## ORCHESTRATION

```yaml
Skills:
  Always:
    - clean-code              # Readable, maintainable
    - type-safety             # TypeScript strict
    - tdd                     # Tests verify behavior

  Load Based on Code:
    - react-deep              # React component refactoring
    - nextjs-deep             # Next.js patterns

Agents:
  Lead: quality               # Quality agent leads
  Consult:
    - architect               # For structural changes
    - frontend/backend        # Based on code type

Knowledge:
  Read First:
    - CRITICAL_NOTES.md       # Patterns to follow
    - progress.txt            # Codebase conventions

  Update After:
    - CRITICAL_NOTES.md       # If new patterns established
    - progress.txt            # Log refactor
```

---

## GOLDEN RULE

```
┌──────────────────────────────────────────────────────────────────┐
│              BEHAVIOR MUST STAY THE SAME                          │
│                                                                   │
│  - Same inputs → Same outputs                                    │
│  - Same side effects                                             │
│  - Same error handling                                           │
│                                                                   │
│           Refactoring = Restructure, NOT Modify                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## PROCESS

```
1. Make ONE small change
2. Run tests
3. Verify behavior unchanged
4. Commit checkpoint
5. Repeat
```

---

## WHAT TO IMPROVE

- [ ] Organization - Better structure
- [ ] Naming - Clearer names
- [ ] Complexity - Simpler logic
- [ ] Duplication - Extract shared code
- [ ] Types - Better TypeScript
- [ ] Patterns - Match conventions

## WHAT NOT TO DO

- Change functionality
- Add features
- Fix bugs (separate task)
- "While I'm here" changes

---

## COMMON REFACTORS

### Extract Function
```typescript
// Before
function processOrder(order) {
  // validate, calculate, save, notify
}

// After
function processOrder(order) {
  const validated = validateOrder(order)
  const calculated = calculateTotal(validated)
  const saved = saveOrder(calculated)
  return notifyUser(saved)
}
```

### Rename for Clarity
```typescript
// Before
const d = getData()
const r = d.filter(x => x.a)

// After
const users = fetchUsers()
const activeUsers = users.filter(user => user.isActive)
```

### Simplify Conditionals
```typescript
// Before
if (user && user.profile && user.profile.settings) {
  theme = user.profile.settings.theme
}

// After
const theme = user?.profile?.settings?.theme ?? 'default'
```

---

## VERIFICATION

After each change:
```bash
npx tsc --noEmit
npm test
npm run lint
```

---

## OUTPUT

```markdown
## Refactor Complete

**What:** [Description]
**Why:** [What improved]

### Files Changed
- `path/file.ts` - [change]

### Verification
- [ ] Tests pass
- [ ] Behavior unchanged
- [ ] TypeScript passes
```

---

## MOBILE PLATFORM

### Mobile Golden Rule

```
┌──────────────────────────────────────────────────────────────────┐
│        BEHAVIOR MUST STAY THE SAME ON BOTH PLATFORMS             │
│                                                                   │
│  - Same inputs → Same outputs                                    │
│  - Same on iOS AND Android                                       │
│  - Test after EVERY change                                       │
│                                                                   │
│           Refactoring = Restructure, NOT Modify                  │
└──────────────────────────────────────────────────────────────────┘
```

### Mobile Process

```
1. Test current behavior on BOTH platforms
2. Make ONE small change
3. Clear Metro cache: npx expo start --clear
4. Test on iOS
5. Test on Android
6. Commit checkpoint
7. Repeat
```

### Common Mobile Refactors

#### Extract Shared Hook

```typescript
// Before: Duplicated logic in screens
function ScreenA() {
  const [data, setData] = useState()
  useEffect(() => { fetchData() }, [])
}

function ScreenB() {
  const [data, setData] = useState()
  useEffect(() => { fetchData() }, [])
}

// After: Shared hook
function useData() {
  const [data, setData] = useState()
  useEffect(() => { fetchData() }, [])
  return { data }
}

function ScreenA() {
  const { data } = useData()
}
```

#### Extract Platform Component

```typescript
// Before: Inline platform checks
function Component() {
  return Platform.OS === 'ios' ? (
    <IOSView />
  ) : (
    <AndroidView />
  )
}

// After: Platform-specific files
// Component.ios.tsx
export function Component() {
  return <IOSView />
}

// Component.android.tsx
export function Component() {
  return <AndroidView />
}
```

#### Migrate to FlashList

```typescript
// Before: FlatList with performance issues
<FlatList
  data={items}
  renderItem={({ item }) => <Item item={item} />}
/>

// After: FlashList for better performance
<FlashList
  data={items}
  renderItem={({ item }) => <Item item={item} />}
  estimatedItemSize={80}
/>
```

#### Extract Styles

```typescript
// Before: Inline styles
<View style={{ padding: 16, backgroundColor: 'white' }}>

// After: StyleSheet
const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: 'white',
  },
})

<View style={styles.container}>
```

### Mobile Verification

After each change:

```bash
# Clear cache
npx expo start --clear

# TypeScript check
npx tsc --noEmit

# Run tests
npm test

# Test on iOS
npx expo run:ios

# Test on Android
npx expo run:android
```

### Mobile Output

```markdown
## Refactor Complete

**What:** [Description]
**Why:** [What improved]

### Files Changed
- `path/file.ts` - [change]

### Verification
- [ ] iOS: Same behavior
- [ ] Android: Same behavior
- [ ] TypeScript passes
- [ ] Tests pass
- [ ] No new warnings
- [ ] No performance regression
```

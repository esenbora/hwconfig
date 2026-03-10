---
name: start-todo
description: Use when starting implementation or executing a plan. Task management and execution. Triggers on: start, begin, execute, implement plan, start tasks, let's go, start building.
argument-hint: "<prd-file-or-plan>"
version: 1.0.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Task
  - TodoWrite
  - AskUserQuestion
---


## OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                    START-TODO WORKFLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. PARSE PLAN                                                  │
│     └─> Read PRD.md / prd.json / PLAN.md                       │
│                                                                 │
│  2. GENERATE TASKS                                              │
│     └─> Break into atomic, testable tasks                       │
│     └─> Each task = 1 context window max                        │
│     └─> Order by dependencies                                   │
│                                                                 │
│  3. CONFIRM TASKS                                               │
│     └─> Show task list to user                                  │
│     └─> Get approval before starting                            │
│                                                                 │
│  4. EXECUTE WITH TDD                                            │
│     └─> For each task:                                          │
│         ├─> Write failing test (RED)                            │
│         ├─> Implement minimum code (GREEN)                      │
│         ├─> Refactor if needed (REFACTOR)                       │
│         ├─> Verify: tsc + lint + test                           │
│         └─> Commit with evidence                                │
│                                                                 │
│  5. UPDATE PROGRESS                                             │
│     └─> Mark task complete in todo.json                         │
│     └─> Update progress.txt                                     │
│     └─> Move to next task                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: PARSE PLAN

### 1.1 Find Plan File

Look for plan in this order:
1. User-provided path: `$ARGUMENTS`
2. `prd.json` (root)
3. `docs/PRD.md`
4. `PLAN.md` (root)
5. `.claude/plan.md`

```bash
# Check for plan files
ls -la prd.json docs/PRD.md PLAN.md .claude/plan.md 2>/dev/null
```

### 1.2 Parse Plan Content

**If prd.json exists:**
```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "...",
      "acceptanceCriteria": ["...", "..."],
      "priority": 1,
      "passes": false
    }
  ]
}
```

**If PRD.md exists:**
- Extract "Must Have" features
- Extract user stories
- Extract acceptance criteria

**If PLAN.md exists:**
- Extract task list
- Extract dependencies

### 1.3 Resume Mode

If `$ARGUMENTS` = "resume":
```bash
# Find existing todo.json
cat todo.json
```

Load existing progress and continue from first incomplete task.

---

## PHASE 2: GENERATE TASKS

### 2.1 Task Sizing Rules

```
┌─────────────────────────────────────────────────────────────────┐
│  TASK SIZING RULES                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ GOOD TASK SIZE:                                              │
│    - Can describe in 2-3 sentences                              │
│    - Has clear acceptance criteria                              │
│    - Can be tested in isolation                                 │
│    - Fits in one context window (~100 lines of new code)        │
│    - Single responsibility                                      │
│                                                                 │
│  ✗ BAD TASK SIZE:                                               │
│    - "Implement authentication" → TOO BIG                       │
│    - "Add button" → TOO SMALL (unless complex)                  │
│    - Multiple unrelated changes → SPLIT IT                      │
│    - Unclear when it's "done" → NEEDS CRITERIA                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Task Structure

Each task must have:

```typescript
interface Task {
  id: string;              // TASK-001, TASK-002, etc.
  title: string;           // Short, descriptive title
  description: string;     // What needs to be done
  type: TaskType;          // setup | feature | test | fix | refactor
  dependencies: string[];  // Task IDs this depends on
  acceptanceCriteria: string[];  // How we know it's done
  testFile?: string;       // Path to test file (if applicable)
  files: string[];         // Files to create/modify
  status: Status;          // pending | in_progress | completed | blocked
  evidence?: Evidence;     // Proof of completion
}

interface Evidence {
  testsPass: boolean;
  tscPasses: boolean;
  lintPasses: boolean;
  screenshot?: string;
  output?: string;
}

type TaskType = 'setup' | 'feature' | 'test' | 'fix' | 'refactor';
type Status = 'pending' | 'in_progress' | 'completed' | 'blocked';
```

### 2.3 Task Ordering

Order tasks by:
1. **Setup tasks first** (project init, deps, config)
2. **Schema/Data layer** (database, types)
3. **Core business logic** (services, actions)
4. **UI components** (reusable components)
5. **Features** (pages, integrations)
6. **Polish** (error handling, loading states)
7. **Testing** (e2e, integration tests)

### 2.4 Generate Task List

**Example task breakdown:**

```json
{
  "project": "MyApp",
  "createdAt": "2024-01-20T10:00:00Z",
  "updatedAt": "2024-01-20T10:00:00Z",
  "totalTasks": 15,
  "completedTasks": 0,
  "currentTask": "TASK-001",
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Project Setup",
      "description": "Initialize Next.js project with TypeScript, Tailwind, and shadcn/ui",
      "type": "setup",
      "dependencies": [],
      "acceptanceCriteria": [
        "Next.js 14 with App Router installed",
        "TypeScript configured (strict mode)",
        "Tailwind CSS configured",
        "shadcn/ui initialized",
        "ESLint + Prettier configured",
        "Dev server runs without errors",
        "tsc --noEmit passes"
      ],
      "files": [
        "package.json",
        "tsconfig.json",
        "tailwind.config.ts",
        "next.config.js",
        ".eslintrc.json",
        ".prettierrc"
      ],
      "status": "pending"
    },
    {
      "id": "TASK-002",
      "title": "Database Setup",
      "description": "Configure Prisma with PostgreSQL and create initial schema",
      "type": "setup",
      "dependencies": ["TASK-001"],
      "acceptanceCriteria": [
        "Prisma installed and configured",
        "DATABASE_URL in .env.example",
        "Initial schema with User model",
        "Migration created and applied",
        "Prisma client generated",
        "Prisma Studio opens"
      ],
      "testFile": "tests/db/connection.test.ts",
      "files": [
        "prisma/schema.prisma",
        "lib/db/index.ts",
        ".env.example"
      ],
      "status": "pending"
    },
    {
      "id": "TASK-003",
      "title": "Authentication Setup",
      "description": "Configure Clerk authentication with sign-in/sign-up pages",
      "type": "feature",
      "dependencies": ["TASK-001"],
      "acceptanceCriteria": [
        "Clerk SDK installed",
        "Environment variables documented",
        "ClerkProvider in root layout",
        "Sign-in page at /sign-in",
        "Sign-up page at /sign-up",
        "Middleware protects /dashboard/*",
        "Auth redirects work correctly"
      ],
      "testFile": "tests/auth/middleware.test.ts",
      "files": [
        "app/(auth)/sign-in/[[...sign-in]]/page.tsx",
        "app/(auth)/sign-up/[[...sign-up]]/page.tsx",
        "middleware.ts",
        "lib/auth/index.ts"
      ],
      "status": "pending"
    }
  ]
}
```

---

## PHASE 3: CONFIRM TASKS

### 3.1 Show Task Summary

Display to user:

```markdown
## Task Plan Generated

**Project:** MyApp
**Total Tasks:** 15
**Estimated Context Windows:** 15

### Task Overview

| # | Task | Type | Dependencies | Files |
|---|------|------|--------------|-------|
| 1 | Project Setup | setup | - | 6 |
| 2 | Database Setup | setup | 1 | 3 |
| 3 | Authentication Setup | feature | 1 | 4 |
| 4 | User Model & Types | feature | 2 | 3 |
| ... | ... | ... | ... | ... |

### Execution Order

1. TASK-001: Project Setup
2. TASK-002: Database Setup
3. TASK-003: Authentication Setup
   ...
```

### 3.2 Get User Approval

```yaml
Questions:
  - header: "Approve Plan"
    question: "Ready to start executing this task plan with TDD?"
    options:
      - label: "Yes, start from beginning"
        description: "Begin with TASK-001"
      - label: "Yes, but skip setup tasks"
        description: "Start from first feature task"
      - label: "Modify tasks first"
        description: "I want to adjust the task list"
      - label: "Cancel"
        description: "Don't start yet"
```

### 3.3 Save Task Plan

Save to `todo.json`:

```bash
# Create todo.json in project root
```

---

## PHASE 4: EXECUTE WITH TDD

### 4.1 TDD Cycle for Each Task

```
┌─────────────────────────────────────────────────────────────────┐
│                      TDD CYCLE                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────┐                                                   │
│   │   RED   │  1. Write failing test                           │
│   │  (test) │     - Test describes expected behavior            │
│   └────┬────┘     - Run test → MUST FAIL                       │
│        │                                                        │
│        ▼                                                        │
│   ┌─────────┐                                                   │
│   │  GREEN  │  2. Write minimum code to pass                   │
│   │ (impl)  │     - Just enough to pass the test               │
│   └────┬────┘     - Run test → MUST PASS                       │
│        │                                                        │
│        ▼                                                        │
│   ┌─────────┐                                                   │
│   │REFACTOR │  3. Clean up (tests still pass)                  │
│   │ (clean) │     - Remove duplication                         │
│   └────┬────┘     - Improve naming                             │
│        │          - Run test → STILL PASSES                    │
│        ▼                                                        │
│   ┌─────────┐                                                   │
│   │ VERIFY  │  4. Full verification                            │
│   │(quality)│     - tsc --noEmit                               │
│   └────┬────┘     - npm run lint                               │
│        │          - npm test                                   │
│        ▼                                                        │
│   ┌─────────┐                                                   │
│   │ COMMIT  │  5. Commit with evidence                         │
│   │ (save)  │     - Meaningful commit message                  │
│   └─────────┘     - Reference task ID                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Task Execution Flow

For each task:

```markdown
## Executing TASK-XXX: [Title]

### Step 1: Update Status
- Mark task as `in_progress` in todo.json
- Update TodoWrite tool

### Step 2: Understand Context
- Read existing files in task.files
- Check dependencies are completed
- Review acceptance criteria

### Step 3: Write Test (RED)
**Only if task.testFile exists**

```typescript
// tests/[feature]/[name].test.ts
import { describe, it, expect } from 'vitest';

describe('[Feature]', () => {
  it('should [expected behavior]', () => {
    // Arrange
    // Act
    // Assert
    expect(result).toBe(expected);
  });
});
```

Run test:
```bash
npm test -- tests/[feature]/[name].test.ts
```

**Expected:** Test FAILS (red)

### Step 4: Implement (GREEN)
- Write minimum code to pass test
- Follow existing patterns
- No extra features

Run test:
```bash
npm test -- tests/[feature]/[name].test.ts
```

**Expected:** Test PASSES (green)

### Step 5: Refactor (if needed)
- Clean up code
- Remove duplication
- Improve names
- Tests still pass

### Step 6: Verify Quality
```bash
# Type check
npx tsc --noEmit

# Lint
npm run lint

# All tests
npm test
```

### Step 7: Collect Evidence
```json
{
  "evidence": {
    "testsPass": true,
    "tscPasses": true,
    "lintPasses": true,
    "output": "[test output snippet]"
  }
}
```

### Step 8: Commit
```bash
git add .
git commit -m "feat(TASK-XXX): [title]

- [what was implemented]
- [acceptance criteria met]

Closes TASK-XXX

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 9: Update Progress
- Mark task as `completed` in todo.json
- Update progress.txt
- Move to next task
```

### 4.3 Handling Failures

**If test doesn't pass after implementation:**

```
1. Re-read the test - is it testing the right thing?
2. Check implementation against acceptance criteria
3. Debug with console.log / breakpoints
4. If stuck after 3 attempts → use build-error-resolver agent
```

**If tsc fails:**

```
1. Read error message carefully
2. Check types match between files
3. If stuck after 3 attempts → use build-error-resolver agent
```

**If lint fails:**

```
1. Run npm run lint:fix
2. If auto-fix doesn't work, fix manually
3. Never disable lint rules without good reason
```

### 4.4 Skip Test for Setup Tasks

For `type: "setup"` tasks:
- No unit test needed
- Verify with commands instead:

```bash
# For project setup
npm run dev  # Should start
npx tsc --noEmit  # Should pass

# For database setup
npx prisma studio  # Should open
npx prisma db push  # Should work

# For auth setup
# Manual verification in browser
```

---

## PHASE 5: UPDATE PROGRESS

### 5.1 Update todo.json

After each task completion:

```json
{
  "updatedAt": "2024-01-20T12:30:00Z",
  "completedTasks": 3,
  "currentTask": "TASK-004",
  "tasks": [
    {
      "id": "TASK-001",
      "status": "completed",
      "completedAt": "2024-01-20T10:30:00Z",
      "evidence": {
        "testsPass": true,
        "tscPasses": true,
        "lintPasses": true,
        "output": "Dev server running at localhost:3000"
      }
    },
    {
      "id": "TASK-002",
      "status": "completed",
      "completedAt": "2024-01-20T11:15:00Z",
      "evidence": {
        "testsPass": true,
        "tscPasses": true,
        "lintPasses": true,
        "output": "Migration applied, Prisma Studio opens"
      }
    },
    {
      "id": "TASK-003",
      "status": "completed",
      "completedAt": "2024-01-20T12:30:00Z",
      "evidence": {
        "testsPass": true,
        "tscPasses": true,
        "lintPasses": true,
        "output": "Auth flow works: sign-in → dashboard"
      }
    },
    {
      "id": "TASK-004",
      "status": "in_progress"
    }
  ]
}
```

### 5.2 Update progress.txt

Add to session log:

```markdown
## 2024-01-20 - start-todo execution

### Completed Tasks
- [x] TASK-001: Project Setup (10:30)
- [x] TASK-002: Database Setup (11:15)
- [x] TASK-003: Authentication Setup (12:30)
- [ ] TASK-004: User Model & Types (in progress)

### Learnings
- Pattern: Using Clerk middleware for route protection
- Pattern: Prisma client singleton in lib/db/index.ts

### Blockers
- None yet
```

### 5.3 Progress Dashboard

Show on each task start:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROGRESS DASHBOARD                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Project: MyApp                                                 │
│  Started: 2024-01-20 10:00                                     │
│                                                                 │
│  Progress: ████████░░░░░░░░░░░░ 20% (3/15 tasks)               │
│                                                                 │
│  ✓ TASK-001: Project Setup                                     │
│  ✓ TASK-002: Database Setup                                    │
│  ✓ TASK-003: Authentication Setup                              │
│  → TASK-004: User Model & Types (current)                      │
│  ○ TASK-005: API Routes Setup                                  │
│  ○ TASK-006: Dashboard Layout                                  │
│  ... 9 more tasks                                              │
│                                                                 │
│  Quality Gates:                                                 │
│  ✓ TypeScript: All tasks passing                               │
│  ✓ Lint: All tasks passing                                     │
│  ✓ Tests: 12/12 passing                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## COMMANDS

### Start Fresh
```
/start-todo docs/PRD.md
```

### Resume Existing
```
/start-todo resume
```

### Skip to Specific Task
```
/start-todo resume --from TASK-005
```

---

## QUALITY RULES

### Never Skip
```
❌ Never mark task complete without evidence
❌ Never skip failing tests
❌ Never ignore TypeScript errors
❌ Never commit without running quality checks
❌ Never move to next task with failing current task
```

### Always Do
```
✓ Write test first (when applicable)
✓ Run tsc --noEmit before commit
✓ Run lint before commit
✓ Run all tests before commit
✓ Update todo.json after each task
✓ Commit after each task
✓ Include evidence of completion
```

### When Stuck
```
1. After 3 failed attempts on same issue → Stop
2. Ask user for guidance OR use build-error-resolver agent
3. Document the blocker in progress.txt
4. Consider marking task as "blocked" and moving on
```

---

## RECOVERY

### If Session Ends Mid-Task

1. Run `/start-todo resume`
2. System reads todo.json
3. Finds last `in_progress` task
4. Continues from where it left off

### If Tests Break After Multiple Tasks

1. Run `git log --oneline -10` to see recent commits
2. Identify which commit broke tests
3. Use `git bisect` if needed
4. Fix the issue
5. Continue with `/start-todo resume`

### If Context Resets

The todo.json file contains all state needed to resume:
- Which tasks are done
- Current task
- Evidence collected

---

## EXAMPLE SESSION

```
User: /start-todo docs/PRD.md

Claude: Let me parse the PRD and generate tasks...

📋 Found PRD: docs/PRD.md
📊 Analyzing features and user stories...

## Task Plan Generated

**Project:** TaskFlow
**Total Tasks:** 12

| # | Task | Type | Est. |
|---|------|------|------|
| 1 | Project Setup | setup | - |
| 2 | Database Schema | setup | - |
| 3 | Auth with Clerk | feature | - |
| 4 | User Profile API | feature | - |
...

Ready to start with TDD?

User: Yes, start from beginning

Claude: Starting TASK-001: Project Setup

┌─────────────────────────────────────────────────────────────────┐
│ TASK-001: Project Setup                                         │
│ Type: setup | Dependencies: none                                │
├─────────────────────────────────────────────────────────────────┤
│ Acceptance Criteria:                                            │
│ □ Next.js 14 with App Router                                   │
│ □ TypeScript strict mode                                        │
│ □ Tailwind + shadcn/ui                                         │
│ □ ESLint + Prettier                                            │
│ □ Dev server runs                                              │
│ □ tsc --noEmit passes                                          │
└─────────────────────────────────────────────────────────────────┘

[Creates project, configures tools...]

Verifying...
✓ npm run dev - Server running at localhost:3000
✓ npx tsc --noEmit - No errors
✓ npm run lint - No warnings

TASK-001 COMPLETE ✓

Committing...
[main abc1234] feat(TASK-001): Project setup with Next.js 14

Moving to TASK-002: Database Schema...
```

---

## REMEMBER

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "The best time to write a test is before the code.           │
│    The second best time is now."                                │
│                                                                 │
│   TDD is not about testing. It's about design.                 │
│   Tests drive better architecture.                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

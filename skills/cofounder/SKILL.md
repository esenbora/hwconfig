---
name: cofounder
version: 1.0.0
description: "Full AI co-founder pipeline: idea → build → launch → promote. Auto-triggers on: cofounder, end to end, full pipeline, idea to launch, idea to ship, start to finish, the whole thing, full workflow, from scratch to launch."
---

# AI Co-Founder - Full Pipeline

You are an AI co-founder running the complete pipeline from idea discovery to shipped, promoted product.

## The Pipeline

```
Step 1: DISCOVER  →  Step 2: BUILD  →  Step 3: LAUNCH  →  Step 4: PROMOTE
  /idea skill          /ship skill       /launch skill      /xpost skill
  [auto]               [auto]            [auto]             [auto]
       ↓ checkpoint         ↓ checkpoint        ↓ checkpoint
    User picks idea     User reviews build   User approves posts
```

## How to Run

### Full Pipeline Mode
When triggered, execute each phase in sequence:

#### Phase 1: Discover
1. Invoke the `cofounder-idea` skill
2. Present 5 scored ideas to user
3. **CHECKPOINT:** Wait for user to pick an idea
4. Save selection to `~/.claude/cofounder/context/current-idea.md`

#### Phase 2: Build
1. Invoke the `cofounder-ship` skill with the selected idea
2. Build the full MVP
3. **CHECKPOINT:** Present the built project to user for review
4. Fix any feedback
5. Save project state to `~/.claude/cofounder/context/current-project.md`

#### Phase 3: Launch
1. Invoke the `cofounder-launch` skill
2. Research competitors, create launch plan, generate all content
3. **CHECKPOINT:** Present launch plan and content for approval
4. Execute approved launch actions

#### Phase 4: Promote
1. Invoke the `cofounder-xpost` skill
2. Generate announcement thread + follow-up content
3. **CHECKPOINT:** Present posts for approval before publishing
4. Post approved content via claude-in-chrome

## State Management

All state is persisted in `~/.claude/cofounder/`:

```
context/
├── current-idea.md       # Selected idea from Phase 1
├── current-project.md    # Built project from Phase 2
├── current-launch.md     # Launch plan from Phase 3
└── pipeline-status.md    # Overall pipeline progress
```

### Pipeline Status File Format
```markdown
# Pipeline Status
Started: YYYY-MM-DD
Idea: [name]
Phase: discover | build | launch | promote | complete
Last checkpoint: [description]
Next action: [what's needed]
```

## Resuming

If the pipeline was interrupted (session ended, user left):
1. Read `~/.claude/cofounder/context/pipeline-status.md`
2. Check episodic-memory for recent session context
3. Resume from the last checkpoint
4. Tell user: "Resuming co-founder pipeline from [phase]. Last we did: [description]"

## Parallel Execution

Within each phase, maximize parallelism:
- Phase 1: Scrape multiple sources simultaneously
- Phase 2: Launch frontend + backend agents in parallel
- Phase 3: Competitor research + content generation in parallel
- Phase 4: Generate multiple post types simultaneously

## Human Checkpoints

**MANDATORY checkpoints (never skip):**
1. After idea presentation → user must pick
2. After build completion → user must review
3. Before any public posting → user must approve

**Optional checkpoints (ask if unsure):**
- Architecture decisions during build
- Pricing model choice
- Launch timing

## Important Rules

- Each phase must fully complete before the next begins
- Always save state between phases for session resilience
- If user says "skip to [phase]", allow jumping with a warning about missing context
- The pipeline is a guide, not a prison. User can diverge at any point.
- Always show progress: "Phase 2 of 4: Building the project..."

---
name: brainstorming
description: Use BEFORE building anything new. Design discussions, planning features, exploring approaches. One question at a time. Triggers on: design, plan, how should i, what's the best way, architecture, approach, before building, let's think, brainstorm, discuss, explore options.
version: 1.0.0
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs through natural collaborative dialogue.

**Core principle:** One question at a time. Validate in small sections. YAGNI ruthlessly.

## The Process

### 1. Understanding the Idea

- Check current project state first (files, docs, recent commits)
- Ask questions ONE AT A TIME to refine the idea
- Prefer multiple choice questions when possible
- Focus on: purpose, constraints, success criteria

### 2. Exploring Approaches

- Propose 2-3 different approaches with trade-offs
- Lead with your recommended option and explain why
- Present options conversationally

### 3. Presenting the Design

- Once you understand what to build, present the design
- Break into sections of 200-300 words
- Ask after EACH section: "Does this look right so far?"
- Cover: architecture, components, data flow, error handling, testing
- Go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to implement?"
- Create detailed implementation plan with bite-sized tasks

## Key Principles

| Principle | Why |
|-----------|-----|
| One question at a time | Don't overwhelm |
| Multiple choice preferred | Easier to answer |
| YAGNI ruthlessly | Remove unnecessary features |
| Explore 2-3 alternatives | Don't jump to first solution |
| Incremental validation | Catch misunderstandings early |
| Be flexible | Go back when something doesn't fit |

## Example Flow

```
User: "I want to add user authentication"

You: "What authentication method do you need?
A) Email/password only
B) Social logins (Google, GitHub)
C) Magic links (passwordless)
D) All of the above"

User: "B - social logins"

You: "Which providers?
A) Google only
B) Google + GitHub
C) Google + GitHub + Apple
D) Other combination"

[Continue one question at a time until design is clear]

You: "Here's the authentication architecture:

**Provider Setup** (Section 1 of 4)
We'll use NextAuth.js with Google and GitHub providers...
[200-300 words]

Does this section look right?"

User: "Yes"

You: "**Database Schema** (Section 2 of 4)
..."
```

## Red Flags

- Asking multiple questions at once
- Jumping to implementation before design is validated
- Presenting entire design in one block
- Not asking "does this look right?" after each section
- Adding features user didn't ask for

---
name: tldr
description: Use for efficient code exploration. Token-efficient code analysis. Triggers on: tldr, explore code, understand code, codebase.
version: 1.0.0
---

# TLDR - Token-Efficient Code Analysis

> 95% token savings when analyzing codebases
> Extract structure, not raw code

---

## Overview

TLDR provides structured code summaries instead of reading raw files. LLMs can't read entire codebases, so we extract structure, trace dependencies, and provide exactly what's needed.

```
Raw files:      23,314 tokens
TLDR summaries: 1,189 tokens  → 95% SAVINGS
```

---

## Quick Start

```bash
# Install
pip install tldr-code
# or
uv tool install llm-tldr

# Index project (one-time)
tldr warm /path/to/project

# Get context for a function
tldr context main --project . --depth 2
```

---

## The 5-Layer Architecture

| Layer | Purpose | Token Cost | Use Case |
|-------|---------|------------|----------|
| **L1: AST** | Structure | ~500 | "What functions exist?" |
| **L2: Call Graph** | Dependencies | +440 | "Who calls what?" |
| **L3: CFG** | Control flow | +110 | "How complex is this?" |
| **L4: DFG** | Data flow | +130 | "Where does this value come from?" |
| **L5: PDG** | Dependencies | +150 | "What affects this line?" |

**Total: ~1,200 tokens vs 23,000 raw**

---

## Essential Commands

### Exploration

```bash
# File tree
tldr tree src/

# Code structure (functions, classes, imports)
tldr structure src/ --lang python
tldr structure src/ --lang typescript

# Full file analysis
tldr extract src/main.py
```

### Context for LLMs

```bash
# Get LLM-ready context from entry point
tldr context main --project . --depth 2
tldr context handleRequest --project . --depth 3

# Semantic search (find by behavior, not text)
tldr semantic "validate JWT tokens" .
tldr semantic "database queries with pagination" .
```

### Call Graph Analysis

```bash
# Build cross-file call graph
tldr calls src/

# Impact analysis: who calls this function?
tldr impact processPayment src/
# → Shows all callers, helps safe refactoring

# Find dead code
tldr dead src/ --entry main cli
```

### Flow Analysis

```bash
# Control flow graph (complexity)
tldr cfg src/auth.py login
# → Shows basic blocks, edges, cyclomatic complexity

# Data flow graph (variable tracking)
tldr dfg src/auth.py login
# → Shows where variables are defined, used, modified

# Program slice (what affects line X?)
tldr slice src/auth.py login 42
# → Shows only the lines that affect line 42
```

### Architecture Analysis

```bash
# Detect architecture layers
tldr arch src/
# → Entry (controllers), Middle (services), Leaf (utils)

# Find circular dependencies
tldr arch src/ | jq '.circular_dependencies'
```

---

## When to Use TLDR

| Task | Instead of | Use |
|------|------------|-----|
| Understand codebase | Reading all files | `tldr structure . --lang ts` |
| Find function callers | grep + manual trace | `tldr impact functionName .` |
| Debug null reference | Read 150-line function | `tldr slice file.py func 42` |
| Before refactoring | grep all usages | `tldr impact oldFunc .` |
| Find relevant code | grep keywords | `tldr semantic "your description"` |
| Check complexity | Manual count | `tldr cfg file.py functionName` |

---

## Workflow Examples

### Exploring New Codebase

```bash
# 1. Get structure
tldr tree src/
tldr structure src/ --lang typescript

# 2. Find entry points
tldr arch src/

# 3. Trace from entry
tldr context main --project . --depth 3
```

### Before Refactoring

```bash
# 1. Find all callers
tldr impact oldFunction src/

# 2. Check complexity
tldr cfg src/module.py oldFunction

# 3. Understand data flow
tldr dfg src/module.py oldFunction
```

### Debugging

```bash
# 1. Find error location
tldr search "raise AuthError" src/

# 2. Get program slice (what leads to that line?)
tldr slice src/auth.py validate_token 47

# 3. Check data flow
tldr dfg src/auth.py validate_token
```

---

## Integration with Krabby

### Before Reading Files

**ALWAYS check TLDR first:**

```bash
# Instead of reading entire file
tldr extract src/services/payment.py

# Instead of grep + read
tldr context processPayment --project . --depth 2
```

### In Skills/Agents

Reference TLDR in system prompts:

```markdown
Before reading large files, use TLDR:
- `tldr structure src/` for overview
- `tldr context functionName` for specific context
- `tldr impact functionName` before refactoring
```

---

## Token Savings Reference

| Scenario | Raw Tokens | TLDR Tokens | Savings |
|----------|------------|-------------|---------|
| Single file | 9,114 | 7,074 | 22% |
| Function + callees | 21,271 | 175 | **99%** |
| Codebase overview | 103,901 | 11,664 | **89%** |
| Deep call chain | 53,474 | 2,667 | **95%** |

---

## Daemon Mode (Faster)

TLDR daemon keeps indexes in memory for instant queries:

```bash
# Daemon auto-starts on first query
tldr context main --project .  # 100ms

# Manual control
tldr daemon start --project .
tldr daemon status --project .
tldr daemon stop --project .
```

| Method | Query Time |
|--------|------------|
| CLI spawn | ~30 seconds |
| Daemon query | ~100ms |
| **Speedup** | **300x** |

---

## Language Support

| Language | AST | Call Graph | CFG | DFG | PDG |
|----------|-----|------------|-----|-----|-----|
| Python | ✅ | ✅ | ✅ | ✅ | ✅ |
| TypeScript | ✅ | ✅ | ✅ | ✅ | ✅ |
| JavaScript | ✅ | ✅ | ✅ | ✅ | ✅ |
| Go | ✅ | ✅ | ✅ | ✅ | ✅ |
| Rust | ✅ | ✅ | ✅ | ✅ | ✅ |
| Swift | ✅ | ✅ | ✅ | ✅ | ✅ |
| + 10 more | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Quick Reference

```bash
# Structure
tldr tree .                    # File tree
tldr structure . --lang py     # Code structure
tldr extract file.py           # Full file analysis

# Context
tldr context func --project .  # LLM-ready context
tldr semantic "description" .  # Find by behavior

# Analysis
tldr calls .                   # Build call graph
tldr impact func .             # Who calls this?
tldr dead .                    # Find dead code
tldr arch .                    # Architecture layers

# Flow
tldr cfg file.py func          # Control flow
tldr dfg file.py func          # Data flow
tldr slice file.py func 42     # Program slice
```

**Rule:** Use TLDR before `cat` or `Read` on large files.

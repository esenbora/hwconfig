# Deep Research Mode

> Evidence-first investigation with citations and confidence levels.

---

## Activation

```yaml
Triggers:
  - Keywords: "research", "investigate", "analyze deeply", "find out"
  - Explicit: "--research", ":research", "investigate:"
  - Task types: debugging mysteries, understanding behavior, finding root cause
```

---

## Configuration

```yaml
require-citations: true
require-confidence: true
multi-hop-search: true
output-format: structured-findings
```

---

## Core Principle

```
NORMAL: Question → Answer
RESEARCH: Question → Sub-questions → Sources → Evidence → Synthesis

NEVER answer without evidence. ALWAYS cite sources.
```

---

## Research Process

### 1. Multi-Hop Search

```
Main Question
    │
    ├── Sub-question 1 → Source A → Finding
    ├── Sub-question 2 → Source B → Finding
    └── Sub-question 3 → Source C → Finding
              │
              ▼
         Synthesis
```

### 2. Confidence Levels

Every claim MUST have a confidence level:

| Level | Range | Criteria |
|-------|-------|----------|
| **HIGH** | 90%+ | Multiple authoritative sources agree |
| **MEDIUM** | 70-89% | Single reliable source or logical inference |
| **LOW** | <70% | Speculation, limited evidence, needs verification |

### 3. Citation Format

```markdown
[1] Source: URL/File | Verified: DATE | Confidence: X%
[2] Source: Official Docs | Verified: DATE | Confidence: X%
```

---

## Output Structure

### Research Report Template

```markdown
# Research: [Topic]

## Executive Summary
[2-3 sentence summary of key findings]

**Overall Confidence:** HIGH/MEDIUM/LOW

---

## Question
[Original question clearly stated]

## Sub-Questions Investigated
1. [Sub-question 1]
2. [Sub-question 2]
3. [Sub-question 3]

---

## Evidence Chain

### Finding 1: [Title]

**Source:** [Citation]
**Confidence:** HIGH/MEDIUM/LOW

[Evidence details]

**Supports:** [What this proves]

### Finding 2: [Title]
...

---

## Synthesis

Based on the evidence:

1. **Confirmed:** [What we know for certain - HIGH confidence]
2. **Likely:** [What's probable - MEDIUM confidence]
3. **Uncertain:** [What needs more investigation - LOW confidence]

---

## Confidence Assessment

| Claim | Confidence | Basis |
|-------|------------|-------|
| [Claim 1] | HIGH | Multiple sources |
| [Claim 2] | MEDIUM | Single source |
| [Claim 3] | LOW | Inference only |

---

## Knowledge Gaps

- [ ] [What we couldn't determine]
- [ ] [What needs further investigation]

---

## Recommendations

Based on findings:
1. [Action 1]
2. [Action 2]

---

## Sources Consulted

[1] [Full citation]
[2] [Full citation]
```

---

## Investigation Patterns

### Debugging Mystery

```markdown
## Investigation: [Bug Description]

### Symptoms
- [Observed behavior 1]
- [Observed behavior 2]

### Hypotheses
1. [Hypothesis A] - will test by [method]
2. [Hypothesis B] - will test by [method]

### Evidence Gathered

#### Test 1: [Description]
**Result:** [Output]
**Conclusion:** [What this tells us]
**Confidence:** HIGH/MEDIUM/LOW

#### Test 2: [Description]
...

### Root Cause
**Finding:** [Root cause]
**Confidence:** HIGH
**Evidence:** [Summary of supporting evidence]

### Solution
[Proposed fix with reasoning]
```

### Understanding Behavior

```markdown
## Investigation: How does [X] work?

### Initial Understanding
[What we thought we knew]

### Research Questions
1. [Specific question 1]
2. [Specific question 2]

### Findings

#### From Official Docs [1]
[Quote or summary]
**Confidence:** HIGH (authoritative source)

#### From Source Code [2]
[What the code shows]
**Confidence:** HIGH (primary source)

#### From Community [3]
[Community insights]
**Confidence:** MEDIUM (secondary source)

### Synthesized Understanding
[Complete picture with confidence levels]
```

---

## Citation Rules

### Required Citations

```yaml
MUST cite:
  - Official documentation
  - Source code references
  - Error messages (exact text)
  - Test results (with commands run)
  
SHOULD cite:
  - Community resources (Stack Overflow, GitHub issues)
  - Blog posts from known experts
  
MARK as LOW confidence:
  - Old documentation (> 1 year)
  - Unofficial sources
  - Your own inference
```

### Citation Format Examples

```markdown
# Official docs
[1] Next.js Docs: https://nextjs.org/docs/app/api-reference | 2024 | HIGH

# Source code
[2] File: src/lib/auth.ts:42-58 | Current | HIGH

# Community
[3] GitHub Issue #1234: https://github.com/... | 2023 | MEDIUM

# Inference
[4] Based on behavior observed in tests | LOW
```

---

## Anti-Patterns (NEVER DO)

```
❌ Making claims without evidence
❌ Skipping confidence levels
❌ Using single source for HIGH confidence
❌ Not acknowledging uncertainty
❌ Mixing speculation with facts
❌ Outdated sources without noting age
```

---

## Exit Conditions

Transition OUT of Research Mode when:

- Investigation complete, findings documented
- User requests action: "OK, let's implement"
- Question fully answered with evidence

---

## Quick Reference

```
Research Mode Rules:
✅ Evidence before claims
✅ Cite all sources
✅ Confidence on every claim
✅ Multi-hop investigation
✅ Acknowledge gaps

Confidence Levels:
HIGH (90%+)   - Multiple authoritative sources
MEDIUM (70-89%) - Single source or inference
LOW (<70%)    - Speculation, needs verification

Output:
- Executive Summary
- Evidence Chain
- Confidence Assessment
- Knowledge Gaps
- Sources
```

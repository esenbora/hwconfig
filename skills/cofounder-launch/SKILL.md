---
name: cofounder-launch
version: 1.0.0
description: "Launch and promote a project. Auto-triggers on: launch this, promote, go to market, Product Hunt, announce, marketing plan, get users, launch strategy, time to launch, release this, ship to users."
---

# Launch & Promote

You are an AI co-founder handling the launch. Your job is to maximize visibility and get first users.

## Pre-Flight

1. **Read current project:** Check `~/.claude/cofounder/context/current-project.md`
2. **If no project context:** Ask what project to launch (one question)
3. **Check episodic-memory** for any past launch context

## Step 1: Competitive Research (Scrapling)

Use ScraplingServer MCP to research competitors:

1. **Scrape competitors** - find 3-5 similar products, analyze their:
   - Landing page copy and structure
   - Pricing model
   - Feature set
   - SEO keywords they rank for
   - Social media presence
2. **Identify gaps** - what are they missing? What can you do better?
3. Save analysis to `~/.claude/cofounder/launches/<project-name>/competitors.md`

**Auto-invoke:** `competitor-alternatives` skill for structured comparison

## Step 2: Landing Page Optimization

**Auto-invoke these skills in sequence:**

1. `copywriting` - write conversion-optimized copy:
   - Hero section: headline + subhead + CTA
   - Problem/solution section
   - Features/benefits
   - Social proof section (even if just "Built by @buzzicra")
   - Pricing section (if applicable)
   - FAQ
   - Final CTA

2. `page-cro` - optimize for conversions:
   - Above-the-fold clarity
   - CTA placement and copy
   - Trust signals
   - Mobile optimization

3. `seo-audit` - optimize for search:
   - Meta title and description
   - Header hierarchy
   - Content optimization

4. `schema-markup` - add structured data:
   - Product schema
   - FAQ schema
   - Organization schema

## Step 3: Launch Plan

**Auto-invoke:** `launch-strategy` skill

Create a launch timeline:

### Pre-Launch (3-5 days before)
- [ ] Landing page live with waitlist/early access
- [ ] Teaser posts on X (@buzzicra) - "Building something..."
- [ ] Set up analytics tracking (`analytics-tracking` skill)
- [ ] Prepare Product Hunt submission
- [ ] Draft launch day X thread

### Launch Day
- [ ] Product Hunt submission (if applicable)
- [ ] X announcement thread (@buzzicra)
- [ ] Show HN post (if dev tool)
- [ ] Reddit posts in relevant subreddits
- [ ] Share in relevant Discord/Slack communities

### Post-Launch (first week)
- [ ] Daily X updates on traction
- [ ] Respond to all comments/feedback
- [ ] Iterate based on user feedback
- [ ] Write "How I built X" blog post/thread

## Step 4: Content Creation

Generate all launch content:

### X Thread (for @buzzicra)
**Auto-invoke:** `social-content` + `marketing-psychology`

Structure:
```
1/ Hook: "I just launched [X] - [compelling one-liner]"
2/ The problem: "Ever tried to [pain point]?"
3/ The solution: "So I built [X] that [benefit]"
4/ Key features (2-3 tweets with screenshots)
5/ Technical angle: "Built with [stack] in [timeframe]"
6/ Social proof / early results
7/ CTA: "Try it free at [URL]"
```

### Product Hunt Tagline & Description
- Tagline: under 60 chars, benefit-focused
- Description: 300 words, problem→solution→features→CTA

### Reddit Post
- Casual, non-promotional tone
- Focus on the problem solved
- Include technical details for dev subreddits

## Step 5: Email Sequence (if applicable)

**Auto-invoke:** `email-sequence` skill

If the project collects emails:
1. Welcome email (immediate)
2. Getting started guide (day 1)
3. Tips & tricks (day 3)
4. Success story / use case (day 7)
5. Upgrade / feedback ask (day 14)

## Step 6: SEO Play

**Auto-invoke:** `programmatic-seo` skill (if applicable)

Identify if programmatic pages make sense:
- "[Tool] for [use case]" pages
- "[Alternative] to [competitor]" pages
- "[Tool] [keyword] template" pages

## Step 7: Save & Transition

1. Save full launch plan to `~/.claude/cofounder/launches/<project-name>/plan.md`
2. Save all generated content to `~/.claude/cofounder/launches/<project-name>/content/`
3. Save to knowledge graph (memory MCP)
4. Tell user: "Launch plan ready. Say 'post this' to start publishing via X, or 'create posts' for more content."

## Browser Actions (claude-in-chrome)

When user approves, use claude-in-chrome to:
- Open X composer and draft the thread
- Open Product Hunt and prepare submission
- Open Reddit and draft posts

**ALWAYS ask for explicit confirmation before posting anything publicly.**

## Important Rules

- Scrape REAL competitor data. Never fabricate competitor analysis.
- All copy must be original and compelling, not generic.
- Respect platform rules (no spam, no fake accounts).
- Always ask before publishing/posting anything.
- Save everything to files so it persists across sessions.

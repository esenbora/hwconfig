---
name: cofounder-idea
version: 1.0.0
description: "Find and validate project ideas with market opportunity. Auto-triggers on: find idea, what should I build, project idea, opportunity, trending, market gap, niche, what's hot, side project, something to build, next project, build something."
---

# Idea Discovery & Validation

You are an AI co-founder helping discover and validate project ideas. Your job is to find ideas that are buildable, marketable, and monetizable.

## Process

### Step 1: Research Trends (Scrapling MCP)

Use the ScraplingServer MCP tools to scrape these sources for trending topics, popular launches, and market gaps:

**Sources to scrape (pick 3-5 based on context):**
- `https://www.producthunt.com` - trending product launches
- `https://news.ycombinator.com/show` - Show HN projects getting traction
- `https://www.indiehackers.com/products` - indie products with revenue
- `https://trends.google.com/trending` - search trends
- `https://github.com/trending` - trending repos (signals dev interest)
- `https://www.reddit.com/r/SideProject/top/?t=week` - side projects getting attention
- `https://www.reddit.com/r/startups/top/?t=week` - startup discussions

Use `stealthy_fetch` for sites with anti-bot (Reddit, etc.). Use `get` for simpler sites. Use CSS selectors to extract only relevant content (titles, descriptions, upvotes).

### Step 2: Analyze & Score (sequential-thinking MCP)

Use the sequential-thinking MCP to methodically evaluate each discovered opportunity:

**Scoring criteria (1-10 each):**

| Criteria | Weight | What to evaluate |
|----------|--------|-----------------|
| Build Speed | 3x | Can it ship in a weekend (10) or needs months (1)? |
| Monetization | 3x | Clear revenue path (10) or unclear (1)? |
| Marketing Angle | 2x | SEO-able, viral potential, community fit? |
| Competition | 2x | Blue ocean (10) or red ocean (1)? |
| Stack Fit | 1x | Matches user's stack (Next.js, Swift, Python)? |
| Trend Timing | 1x | Rising trend (10) or declining (1)? |

**Weighted score = sum of (score x weight) / total weight**

### Step 3: Generate Ideas

Based on research, generate **5 ideas** in this format:

```markdown
## Idea: [Name]

**One-liner:** [What it does in 10 words]
**Type:** Web App | iOS App | Chrome Extension | API | CLI Tool
**Build time:** Weekend | 1 Week | 2 Weeks | 1 Month
**Revenue model:** Freemium | Paid | Ads | API pricing | Open-source + paid features
**Score:** [X/10]

**Why now:** [What trend/gap makes this timely]
**Marketing angle:** [How to get first users]
**Competition:** [Who exists, what's their weakness]
**MVP scope:** [Minimum features to launch]
```

### Step 4: Present & Save

1. Present the top 5 ideas ranked by score
2. Recommend the #1 pick with reasoning
3. Save the full analysis to `~/.claude/cofounder/ideas/YYYY-MM-DD-ideas.md`
4. Save to knowledge graph (memory MCP) for cross-session recall

### Step 5: Transition

After user picks an idea, save the selected idea to `~/.claude/cofounder/context/current-idea.md` and tell the user they can say "let's build this" or "ship it" to start the `/ship` workflow.

## Auto-Invoke These Skills

- `marketing-ideas` - for additional marketing angle validation
- `pricing-strategy` - for monetization validation
- `content-strategy` - for content marketing potential

## Auto-Use These MCPs

- **ScraplingServer** - web scraping (primary research tool)
- **sequential-thinking** - structured analysis
- **memory** - save entities to knowledge graph
- **episodic-memory** - check if similar ideas were explored before

## Important Rules

- Always scrape REAL data. Never make up trends or fake what's trending.
- If Scrapling fails on a source, try `stealthy_fetch` instead of `get`, or skip that source and note it.
- Score honestly. Don't inflate scores to make ideas look better.
- Consider the user's existing projects (50+ in ~/Desktop/) to avoid duplicates.
- Prefer ideas that can launch in under 2 weeks.

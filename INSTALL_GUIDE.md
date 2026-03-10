# Krabby 2026 v7.0 - Installation Guide

> A comprehensive Claude Code system for web and mobile development.

---

## Quick Install (Recommended)

```bash
# 1. Backup existing config (if any)
[ -d ~/.claude ] && mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# 2. Clone the system
git clone https://github.com/bulbulogludemir/krabby-the-coder.git ~/.claude

# 3. Restart Claude Code
# Close and reopen your terminal, then run:
claude
```

---

## Manual Installation

### Step 1: Create Directory Structure

```bash
mkdir -p ~/.claude/{skills,agents,rules,hooks/scripts,memory,modes,templates}
```

### Step 2: Copy Core Files

Required files:
```
~/.claude/
├── CLAUDE.md              # Main instructions (v7.0)
├── DONT_DO.md             # Failed approaches log
├── CRITICAL_NOTES.md      # Project constraints
├── settings.json          # Hooks & permissions
├── agents/                # 28 specialized agents
├── skills/                # 87 domain skills
├── rules/                 # 5 permission rules
├── hooks/scripts/         # 11 automation hooks
├── modes/                 # 3 operation modes
├── memory/                # Learning system
└── templates/             # Request templates
```

### Step 3: Configure settings.json

Minimum required settings:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/scripts/error-capture.sh 2>/dev/null || true"
          },
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/scripts/loop-detector.sh 2>/dev/null || true",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

---

## What's Included

### 87 Skills

| Category | Skills |
|----------|--------|
| **Frontend** | react, react-19, nextjs, tailwind, shadcn, framer-motion, component-patterns |
| **Backend** | server-actions, trpc, middleware, background-jobs, webhook-reliability |
| **Database** | supabase, drizzle, prisma, postgresql, redis, caching |
| **Auth** | clerk, nextauth, auth-security, session-security |
| **Mobile** | expo, swift, react-native patterns |
| **Security** | 10+ security skills (api, auth, llm, mcp, owasp, etc.) |
| **Testing** | vitest, playwright, tdd, test |
| **DevOps** | docker, ci-cd, github-actions, vercel |
| **Quality** | clean-code, type-safety, defensive-coding, production-mindset |
| **New in v7** | intent-clarifier, load-testing, feature-flags, rollback-strategies, monorepo |

### 28 Agents

| Agent | Purpose |
|-------|---------|
| `architect` | System design, tech decisions |
| `frontend` | React, UI, components |
| `backend` | APIs, server logic |
| `mobile-rn` | React Native, Expo |
| `mobile-ios` | Swift, iOS native |
| `security` | Security audits |
| `verifier` | Verification before done |
| `quality` | Code review |
| `performance` | Optimization |
| +19 more | Various specializations |

### 5 Rules Files

| File | Purpose |
|------|---------|
| `00-core.md` | Core auto-approve/block rules |
| `10-security.md` | Security operation rules |
| `20-git.md` | Git operation rules |
| `30-testing.md` | Test execution rules |
| `README.md` | Rules documentation |

### 11 Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-init.sh` | Session start | Initialize session |
| `knowledge-loader.sh` | Session start | Load DONT_DO, patterns |
| `resume-handoff.sh` | Session start | Resume from handoff |
| `pre-commit.sh` | Before git commit | Quality checks |
| `post-edit-quality.sh` | After Write/Edit | TypeScript check |
| `error-capture.sh` | After Bash errors | Learn from failures |
| `loop-detector.sh` | After Bash | Detect repeated errors |
| `create-handoff.sh` | Before compact | Save context |
| `session-end.sh` | Session end | Cleanup |
| `learning-persist.sh` | Session end | Save learnings |
| `project-setup.sh` | New project | Initial setup |

### 3 Modes

| Mode | Use Case |
|------|----------|
| `architect` | System design, planning |
| `rapid` | Quick fixes, small changes |
| `deep-research` | Investigation, analysis |

---

## Customization

### Add Your Tech Stack

Edit `~/.claude/CLAUDE.md`:

```markdown
## Your Tech Stack

| Category | Technologies |
|----------|-------------|
| **Web** | [Your frameworks] |
| **Database** | [Your DB] |
...
```

### Add Project-Specific Rules

Create `YOUR_PROJECT/.claude/CLAUDE.md` for project-specific instructions.

### Add Custom Skills

```bash
mkdir ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Description and triggers
version: 1.0.0
---

# My Skill

Content here...
EOF
```

---

## Verification

After installation, verify with:

```bash
# Check structure
ls -la ~/.claude/

# Count components
echo "Skills: $(ls ~/.claude/skills/ | wc -l)"
echo "Agents: $(ls ~/.claude/agents/*.md | wc -l)"
echo "Rules: $(ls ~/.claude/rules/*.md | wc -l)"

# Validate settings.json
python3 -c "import json; json.load(open('$HOME/.claude/settings.json')); print('✅ Valid')"

# Test in Claude Code
claude
# Then type: "what skills do you have?"
```

---

## Updating

```bash
cd ~/.claude
git pull origin main
```

---

## Troubleshooting

### Hooks Not Running

1. Check `settings.json` syntax
2. Verify hook scripts are executable: `chmod +x ~/.claude/hooks/scripts/*.sh`
3. Check hook output: Run the script manually

### Skills Not Loading

1. Verify skill has valid frontmatter (--- block)
2. Check skill has `name:` and `description:`
3. Restart Claude Code session

### Memory Not Persisting

1. Check `~/.claude/memory/` is writable
2. Verify `learnings.jsonl` exists
3. Check hook scripts for errors

---

## Support

- Issues: [GitHub Issues URL]
- Updates: Watch the repo for new versions

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v7.0 | 2026-01-24 | Full lifecycle, verifier agent, intent-clarifier |
| v6.2 | 2026-01-15 | Quality hooks, sharp-edges |
| v6.0 | 2026-01-01 | Initial release |

---

*Krabby 2026 v7.0 - 87 skills, 28 agents, full lifecycle coverage*

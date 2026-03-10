# Claude Code - HWConfig

Birebir kopyalanmis Claude Code konfigurasyonu. Stat401 odevlerini (HW1, HW2, HW3) yaparken kullanilan tum MCP serverlari, pluginler, skilller, agentlar, hooklar, kurallar ve ayarlar.

## Icerik

```
.
├── CLAUDE.md                     # Ana talimatlar (her session'da yuklenir)
├── CRITICAL_NOTES.md             # Kritik notlar
├── DONT_DO.md                    # Yapilmamasi gerekenler
├── STANDARDS.md                  # Kod standartlari
├── INSTALL_GUIDE.md              # Kurulum rehberi
├── settings.json                 # Ana ayarlar (hooks, plugins, permissions)
├── settings.local.json           # Lokal izinler
├── statusline-command.sh         # Status line scripti
├── rules/                        # Kurallar (permissions, security, auto-invoke, integrity)
├── hooks/                        # Hook scriptleri (session-start, pre-commit, vb.)
│   └── scripts/                  # Yardimci scriptler
├── modes/                        # Ozel modlar (architect, deep-research, rapid)
├── skills/                       # 147 skill dosyasi
├── agents/                       # 36 agent tanimi
├── templates/                    # Sablonlar
├── commands/                     # Ozel komutlar
├── memory/                       # Kalici hafiza dosyalari
├── mcp-configs/                  # Tum MCP server konfigurasyonlari
│   ├── dot-mcp.json              # ~/.claude/.mcp.json
│   ├── claude_mcp_config.json    # Ek MCP config
│   ├── claude_desktop_config.json # Claude Desktop MCP config
│   ├── cursor_mcp.json           # Cursor IDE MCP config
│   └── chrome_native_messaging.json
├── plugins/
│   └── installed_plugins.json    # Kurulu plugin listesi
└── cofounder/                    # Co-founder pipeline dosyalari
```

## Kurulum

```bash
# 1. Claude Code CLI
npm install -g @anthropic-ai/claude-code

# 2. Dosyalari kopyala
cp CLAUDE.md ~/.claude/CLAUDE.md
cp settings.json ~/.claude/settings.json
cp settings.local.json ~/.claude/settings.local.json
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

cp -r rules/ ~/.claude/rules/
cp -r hooks/ ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh ~/.claude/hooks/scripts/*.sh
cp -r modes/ ~/.claude/modes/
cp -r skills/ ~/.claude/skills/
cp -r agents/ ~/.claude/agents/
cp -r templates/ ~/.claude/templates/
cp -r commands/ ~/.claude/commands/
cp -r memory/ ~/.claude/memory/

cp mcp-configs/dot-mcp.json ~/.claude/.mcp.json
cp mcp-configs/claude_mcp_config.json ~/.claude/claude_mcp_config.json

# 3. Pluginleri kur
claude plugins install superpowers@superpowers-marketplace
claude plugins install superpowers-chrome@superpowers-marketplace
claude plugins install superpowers-lab@superpowers-marketplace
claude plugins install episodic-memory@superpowers-marketplace
claude plugins install elements-of-style@superpowers-marketplace
claude plugins install double-shot-latte@superpowers-marketplace
claude plugins install superpowers-developing-for-claude-code@superpowers-marketplace
claude plugins install frontend-design@claude-code-plugins
claude plugins install ralph-wiggum@claude-code-plugins
claude plugins install agent-sdk-dev@claude-code-plugins

# 4. MCP yollarini kendi sistemine gore duzelt
```

# Claude Code - Homework Config

Stat401 Big Data odevlerini (HW1, HW2, HW3) yaparken kullanilan Claude Code konfigurasyonu.
Conversation loglarindan cikarilan gercek kullanim verileri:

## Kullanilan Araclar (session loglarindan)

| Arac | Kullanim | Aciklama |
|------|----------|----------|
| `Bash` | 51 kez | Python scriptleri calistirma, pip install, dosya islemleri |
| `Read` | 44 kez | PDF okuma, assignment dosyalari, paper okuma |
| `mcp__humanizer__detect` | 43 kez | AI-yazilmis metni tespit etme / humanize kontrolu |
| `NotebookEdit` | 13 kez | Jupyter notebook hucreleri olusturma/duzenleme |
| `Edit` | 12 kez | Mevcut dosyalari duzenleme |
| `Write` | 10 kez | Yeni dosya olusturma (generate_pdf.py, run_benchmark.py) |
| `mcp__puppeteer__*` | 22 kez | Tarayici otomasyonu (screenshot, navigate, evaluate, fill, click) |
| `Glob` | 7 kez | Dosya arama |
| `mcp__episodic-memory__*` | 5 kez | Onceki odev session'larini hatirlama |
| `Grep` | 2 kez | Icerik arama |
| `AskUserQuestion` | 2 kez | Kullaniciya soru sorma |
| `mcp__claude-in-chrome__*` | 1 kez | Chrome tarayici kontrolu |

## MCP Serverlari

```
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /Users/YOUR_USERNAME
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add browser-tools -- npx -y @agentdeskai/browser-tools-mcp
claude mcp add humanizer -- npx -y ai-humanizer-mcp-server
```

## Pluginler

```
claude plugins install episodic-memory@superpowers-marketplace
claude plugins install double-shot-latte@superpowers-marketplace
claude plugins install superpowers@superpowers-marketplace
claude plugins install superpowers-chrome@superpowers-marketplace
```

## Hooklar (otomatik calisan)

- `session-start.sh` - Proje bilgisi gosterir
- `pre-tool-use.sh` - Edit/Write oncesi kontrol
- `post-tool-use-sync.sh` - Edit/Write sonrasi dosya senkron

## Ayarlar

- `effortLevel: "high"` - Maksimum caba
- `acceptEdits` - Dosya duzenlemelerini otomatik onayla

## Kurulum

```bash
# 1. Claude Code
npm install -g @anthropic-ai/claude-code

# 2. MCP Serverlari ekle
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /Users/YOUR_USERNAME
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add browser-tools -- npx -y @agentdeskai/browser-tools-mcp
claude mcp add humanizer -- npx -y ai-humanizer-mcp-server

# 3. Pluginleri kur
claude plugins install episodic-memory@superpowers-marketplace
claude plugins install double-shot-latte@superpowers-marketplace
claude plugins install superpowers@superpowers-marketplace
claude plugins install superpowers-chrome@superpowers-marketplace

# 4. Ayarlari kopyala
cp settings.json ~/.claude/settings.json
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 5. Cursor IDE'de ac (Jupyter kernel icin gerekli)
```

# Claude Code - HWConfig

Minimal Claude Code configuration for doing homework.

## What This Enables

- **File read/write** - Read assignment PDFs, write Python scripts, edit Jupyter notebooks
- **Sequential thinking** - Complex multi-step reasoning for algorithm analysis and proofs
- **Knowledge graph** - Persist concepts and facts across sessions
- **Jupyter execution** - Run notebook cells directly (requires Cursor/VS Code IDE)
- **Cross-session memory** - Remember previous homework context

## Prerequisites

1. **Claude Code CLI**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Cursor IDE** (or VS Code with Claude Code extension)
   - The IDE integration provides Jupyter kernel execution (`mcp__ide__executeCode`)
   - This is what actually runs Python code in notebooks

3. **Python environment**
   ```bash
   pip install numpy matplotlib seaborn scipy pandas scikit-learn jupyter
   ```

## Installation

### 1. Copy MCP server config

```bash
cp .mcp.json ~/.claude/.mcp.json
```

Edit the `filesystem` server path to point to your homework directory.

Or add servers individually:
```bash
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/homework
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
```

### 2. Copy settings

```bash
cp settings.json ~/.claude/settings.json
```

### 3. Install plugins

```bash
claude plugins install episodic-memory@superpowers-marketplace
claude plugins install double-shot-latte@superpowers-marketplace
claude plugins install superpowers@superpowers-marketplace
```

### 4. Open homework in Cursor

Open the homework folder in Cursor, then launch Claude Code from the terminal. The IDE integration will automatically provide Jupyter kernel access.

## What Each Component Does

| Component | Purpose | Used For |
|-----------|---------|----------|
| `filesystem` MCP | Read/write files | Reading assignments, writing scripts, managing data files |
| `sequential-thinking` MCP | Step-by-step reasoning | Algorithm analysis, mathematical proofs, complex derivations |
| `memory` MCP | Knowledge graph | Remembering paper concepts, formulas, definitions across sessions |
| `episodic-memory` plugin | Conversation search | Finding past homework solutions and approaches |
| `double-shot-latte` plugin | Auto-continuation | Prevents Claude from stopping prematurely on long tasks |
| `superpowers` plugin | Core skills | Brainstorming, debugging, systematic problem-solving |
| Cursor IDE integration | Jupyter kernel | Executing Python code cells in `.ipynb` notebooks |

## Usage

1. Open homework folder in Cursor
2. Open terminal, run `claude`
3. Give the assignment: "Read the assignment file and the reference paper, then create the Jupyter notebook"
4. Claude will:
   - Read the assignment PDF/markdown
   - Read reference papers
   - Create/edit `.ipynb` notebooks with code + markdown explanations
   - Run cells via IDE integration
   - Generate plots (matplotlib/seaborn)
   - Generate PDF reports

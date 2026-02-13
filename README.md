# FlowMind Skill for Claude Code

[![FlowMind](https://img.shields.io/badge/FlowMind-Productivity-blue)](https://flowmind.life)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Connect [Claude Code](https://docs.anthropic.com/en/docs/claude-code) to [FlowMind](https://flowmind.life) — your personal productivity platform for goals, tasks, and notes.

## Features

- 🎯 **Goals** — Create and track goals with categories
- ✅ **Tasks** — Manage tasks with priorities, due dates, and focus
- 📝 **Notes** — Capture ideas and information
- 🔥 **Focus** — Set and view today's focus tasks

## Installation

```bash
/plugin marketplace add haohappy/cc-skill-flowmind
/plugin install flowmind@cc-skill-flowmind
```

## Setup

1. Go to [FlowMind](https://flowmind.life) and sign in
2. Click your avatar → **Settings** → **API Keys**
3. Click **Generate New Key** and copy it (starts with `fm_`)
4. Configure the skill:

```bash
mkdir -p ~/.flowmind
echo '{"api_key": "fm_YOUR_KEY", "base_url": "https://flowmind.life/api/v1"}' > ~/.flowmind/config.json
```

## Usage

```
/flowmind add task "Review quarterly report" --priority high --due 2025-01-15
/flowmind add goal "Launch MVP" --category business
/flowmind add note "Meeting notes"
/flowmind list tasks
/flowmind list goals
/flowmind focus
```

## Commands

| Command | Description |
|---------|-------------|
| `add task <title>` | Create a task |
| `add goal <title>` | Create a goal |
| `add note <title>` | Create a note |
| `list tasks` | List all tasks |
| `list goals` | List all goals |
| `list notes` | List all notes |
| `focus` | Show today's focus |
| `focus <id>` | Set task as focus |

## Task Options

| Option | Values |
|--------|--------|
| `--priority` | low, medium, high, urgent |
| `--due` | YYYY-MM-DD |
| `--status` | todo, in_progress, completed |
| `--goal` | Goal ID to link |

## Goal Options

| Option | Values |
|--------|--------|
| `--category` | business, career, health, personal, learning, financial |
| `--target` | YYYY-MM-DD |

## Links

- [FlowMind](https://flowmind.life)
- [GitHub Issues](https://github.com/haohappy/cc-skill-flowmind/issues)

## License

MIT

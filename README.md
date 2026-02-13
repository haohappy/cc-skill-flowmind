# FlowMind Skill for Claude Code

[![FlowMind](https://img.shields.io/badge/FlowMind-Productivity-blue)](https://flowmind.life)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Connect [Claude Code](https://claude.ai/code) to [FlowMind](https://flowmind.life) - your personal productivity platform for goals, tasks, and focus.

## Features

- 🎯 **Goals** - Create and track goals with categories and progress
- ✅ **Tasks** - Manage tasks with priorities, due dates, and subtasks
- 📝 **Notes** - Capture ideas and information
- 🔥 **Focus** - Set and view today's focus tasks

## Installation

```bash
/plugin marketplace add haohappy/cc-skill-flowmind
/plugin install cc-skill-flowmind@cc-skill-flowmind
```

## Quick Start

### 1. Get Your API Key

1. Go to [FlowMind](https://flowmind.life) and sign in
2. Click your avatar → **Settings**
3. Navigate to **API Keys**
4. Click **Generate New Key**
5. Copy the key (starts with `fm_`)

### 2. Configure

```bash
./scripts/flowmind.sh config fm_your_api_key_here
```

### 3. Start Using

```bash
# Create a task
./scripts/flowmind.sh add-task "Review quarterly report" -p high --due 2025-01-15

# Create a goal
./scripts/flowmind.sh add-goal "Launch MVP" -c business --target 2025-03-01

# Create a note
./scripts/flowmind.sh add-note "Meeting notes"

# List tasks
./scripts/flowmind.sh list-tasks --status todo

# Set focus
./scripts/flowmind.sh focus <task_id>
```

## Commands

| Command | Description |
|---------|-------------|
| `config [key]` | Configure API key |
| `add-task <title>` | Create a task |
| `add-goal <title>` | Create a goal |
| `add-note <title>` | Create a note |
| `list-tasks` | List tasks |
| `list-goals` | List goals |
| `list-notes` | List notes |
| `focus <id>` | Set task as focus |
| `focus --list` | View today's focus |

## Task Options

| Option | Description |
|--------|-------------|
| `-d, --description` | Task description |
| `-p, --priority` | low, medium, high, urgent |
| `--due` | Due date (YYYY-MM-DD) |
| `--goal` | Link to goal ID |

## Goal Options

| Option | Description |
|--------|-------------|
| `-d, --description` | Goal description |
| `-c, --category` | business, career, health, personal, learning, financial |
| `--target` | Target date (YYYY-MM-DD) |

## Requirements

- `curl` - For API requests
- `jq` - For JSON parsing

## Documentation

- [FlowMind Website](https://flowmind.life)
- [API Documentation](https://docs.flowmind.life)
- [SKILL.md](./SKILL.md) - Detailed usage guide

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- [GitHub Issues](https://github.com/haohappy/cc-skill-flowmind/issues)
- [FlowMind Support](https://flowmind.life/support)

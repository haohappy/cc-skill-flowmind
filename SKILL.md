# FlowMind Skill

Connect Claude Code to [FlowMind](https://flowmind.life) - your personal productivity platform for goals, tasks, and focus.

## Setup

### 1. Get Your API Key
1. Go to [FlowMind](https://flowmind.life) and sign in
2. Click your avatar → **Settings**
3. Navigate to **API Keys**
4. Click **Generate New Key**
5. Copy the key (it starts with `fm_`)

### 2. Configure the Skill
Run the config command and paste your API key:
```bash
./scripts/flowmind.sh config <YOUR_API_KEY>
```

Or manually create `~/.flowmind/config.json`:
```json
{
  "api_key": "fm_your_api_key_here"
}
```

## Commands

### Tasks

**Create a task:**
```bash
./scripts/flowmind.sh add-task "Task title" --description "Details" --priority high --due "2025-12-31"
```

Options:
- `--description` or `-d`: Task description
- `--priority` or `-p`: low, medium, high, urgent (default: medium)
- `--due`: Due date (YYYY-MM-DD format)
- `--goal`: Goal ID to link the task to

**List tasks:**
```bash
./scripts/flowmind.sh list-tasks [--status todo|in_progress|completed] [--priority high]
```

### Goals

**Create a goal:**
```bash
./scripts/flowmind.sh add-goal "Goal title" --description "Details" --category business --target "2025-12-31"
```

Options:
- `--description` or `-d`: Goal description
- `--category` or `-c`: business, career, health, personal, learning, financial
- `--target`: Target date (YYYY-MM-DD format)

**List goals:**
```bash
./scripts/flowmind.sh list-goals [--status active|completed] [--category business]
```

### Notes

**Create a note:**
```bash
./scripts/flowmind.sh add-note "Note title" --content "Note content here"
```

For long content, you can pipe it:
```bash
echo "Your long note content..." | ./scripts/flowmind.sh add-note "Note title" --stdin
```

**List notes:**
```bash
./scripts/flowmind.sh list-notes
```

### Focus

**Set today's focus:**
```bash
./scripts/flowmind.sh focus <task_id>
```

**View today's focus:**
```bash
./scripts/flowmind.sh focus --list
```

## API Reference

Base URL: `https://flowmind.life/api/v1`

| Resource | Endpoints |
|----------|-----------|
| Goals | GET/POST /goals, GET/PATCH/DELETE /goals/:id |
| Tasks | GET/POST /tasks, GET/PATCH/DELETE /tasks/:id |
| Notes | GET/POST /notes, GET/PATCH/DELETE /notes/:id |
| People | GET/POST /people, GET/PATCH/DELETE /people/:id |
| Tags | GET/POST /tags, GET/PATCH/DELETE /tags/:id |

Full docs: https://docs.flowmind.life

## Examples

### Morning Planning Workflow
```bash
# Check today's focus
./scripts/flowmind.sh focus --list

# Add a new task for today
./scripts/flowmind.sh add-task "Review quarterly report" -p high --due "$(date +%Y-%m-%d)"

# Set it as focus
./scripts/flowmind.sh focus <task_id>
```

### Project Setup
```bash
# Create a goal
./scripts/flowmind.sh add-goal "Launch MVP" -c business --target "2025-03-01"

# Add tasks linked to the goal
./scripts/flowmind.sh add-task "Design wireframes" --goal <goal_id> -p high
./scripts/flowmind.sh add-task "Build backend API" --goal <goal_id> -p high
./scripts/flowmind.sh add-task "User testing" --goal <goal_id> -p medium
```

## Troubleshooting

**"Unauthorized" error:**
- Check your API key is correct
- Regenerate a new key from FlowMind settings

**"Not found" error:**
- Verify the resource ID exists
- Check you have access to that resource

## Support

- Website: https://flowmind.life
- Docs: https://docs.flowmind.life
- Issues: https://github.com/haohappy/cc-skill-flowmind/issues

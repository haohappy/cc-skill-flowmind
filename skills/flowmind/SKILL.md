---
name: flowmind
description: Manage goals, tasks, notes, people, and tags with FlowMind. Use when user wants to create/list/update/delete productivity items, track goals, manage contacts, or organize with tags.
---

## FlowMind Productivity Skill

Connect to [FlowMind](https://flowmind.life) to manage goals, tasks, notes, people, and tags.

## Setup

User needs to configure their API key:

```bash
mkdir -p ~/.flowmind
echo '{"api_key": "fm_xxx", "base_url": "https://flowmind.life/api/v1"}' > ~/.flowmind/config.json
```

Get API key from: FlowMind → Settings → API Keys → Generate New Key

## Usage Examples

<example>
User: /flowmind help
Assistant: [Shows the help text below]
</example>

<example>
User: /flowmind help tasks
Assistant: [Shows task commands and options]
</example>

<example>
User: /flowmind add task "Review report" --priority high --due 2025-01-15
Assistant: [Creates task via POST /tasks, confirms with task ID]
</example>

<example>
User: /flowmind list tasks --status todo
Assistant: [Fetches GET /tasks?status=todo, displays as table]
</example>

<example>
User: /flowmind update task abc123 --status completed
Assistant: [Updates via PATCH /tasks/abc123, confirms]
</example>

<example>
User: /flowmind delete goal xyz789
Assistant: [Deletes via DELETE /goals/xyz789, confirms]
</example>

## Instructions

### 1. Check Configuration

```bash
cat ~/.flowmind/config.json
```

If missing, guide user to set up (see Setup section).

### 2. Handle Help Command

If user types `help`, `--help`, or `help <topic>`, show the relevant help text:

**`/flowmind help`** → Show:
```
FlowMind - Productivity management for Claude Code

Commands:
  list <resource>              List items (goals/tasks/notes/people/tags)
  add <resource> <title>       Create new item
  get <resource> <id>          Get item details
  update <resource> <id>       Update an item
  delete <resource> <id>       Delete an item

Resources: goals, tasks, notes, people, tags

Examples:
  /flowmind add task "Buy groceries" --priority high
  /flowmind list tasks --status todo
  /flowmind update task abc123 --status completed

Type /flowmind help <resource> for detailed options.
```

**`/flowmind help goals`** → Show goal commands and all options
**`/flowmind help tasks`** → Show task commands and all options
**`/flowmind help notes`** → Show note commands and all options
**`/flowmind help people`** → Show people commands and all options
**`/flowmind help tags`** → Show tag commands and all options

### 3. Parse User Request & Make API Call

Use curl with Bearer token from config.

---

## Commands Reference

### Goals

| Command | API | Description |
|---------|-----|-------------|
| `list goals` | GET /goals | List all goals |
| `add goal <title>` | POST /goals | Create a goal |
| `get goal <id>` | GET /goals/:id | Get goal details |
| `update goal <id>` | PATCH /goals/:id | Update a goal |
| `delete goal <id>` | DELETE /goals/:id | Delete a goal |

**Goal Options:**
- `--description` — Goal description
- `--category` — business, career, health, personal, learning, financial
- `--target` — Target date (YYYY-MM-DD)
- `--status` — active, completed, archived
- `--progress` — 0-100
- `--pinned` — true/false

**Goal Fields:** id, title, description, status, category, target_date, progress, pinned, created_at, updated_at

---

### Tasks

| Command | API | Description |
|---------|-----|-------------|
| `list tasks` | GET /tasks | List all tasks |
| `add task <title>` | POST /tasks | Create a task |
| `get task <id>` | GET /tasks/:id | Get task details |
| `update task <id>` | PATCH /tasks/:id | Update a task |
| `delete task <id>` | DELETE /tasks/:id | Delete a task |
| `list subtasks <id>` | GET /tasks/:id/subtasks | List subtasks |
| `add subtask <parent_id> <title>` | POST /tasks/:id/subtasks | Create subtask |

**Task Options:**
- `--description` — Task description
- `--priority` — low, medium, high, urgent
- `--status` — todo, in_progress, completed, archived
- `--energy` — low, medium, high
- `--due` — Due date (YYYY-MM-DD)
- `--goal` — Link to goal ID
- `--person` — Link to person ID
- `--estimated` — Estimated minutes
- `--pinned` — true/false
- `--focus` — true/false (today's focus)

**Task Filters (for list):**
- `--status` — Filter by status
- `--priority` — Filter by priority
- `--goal` — Filter by goal_id
- `--due-from` — Due date from (YYYY-MM-DD)
- `--due-to` — Due date to (YYYY-MM-DD)
- `--focus` — Show focus tasks only

**Task Fields:** id, title, description, status, priority, energy_level, due_date, scheduled_time, goal_id, person_id, parent_task_id, estimated_minutes, actual_minutes, pinned, focused, focus_today, created_at, updated_at

---

### Notes

| Command | API | Description |
|---------|-----|-------------|
| `list notes` | GET /notes | List all notes |
| `add note <title>` | POST /notes | Create a note |
| `get note <id>` | GET /notes/:id | Get note details |
| `update note <id>` | PATCH /notes/:id | Update a note |
| `delete note <id>` | DELETE /notes/:id | Delete a note |

**Note Options:**
- `--content` — Note body (markdown supported)
- `--category` — Note category
- `--task` — Link to task ID
- `--pinned` — true/false

**Note Fields:** id, title, content, category, task_id, is_protected, pinned, created_at

---

### People

| Command | API | Description |
|---------|-----|-------------|
| `list people` | GET /people | List all people |
| `add person <name>` | POST /people | Create a person |
| `get person <id>` | GET /people/:id | Get person details |
| `update person <id>` | PATCH /people/:id | Update a person |
| `delete person <id>` | DELETE /people/:id | Delete a person |

**Person Options:**
- `--email` — Email address
- `--phone` — Phone number
- `--company` — Company name
- `--role` — Job role/title
- `--relationship` — business, colleague, friend, family, mentor, client, partner, other
- `--notes` — Notes about person
- `--location` — Location string

**Person Fields:** id, name, email, phone, company, role, relationship_type, notes, avatar_url, birth_month, birth_day, zodiac_sign, mbti_type, location, last_met_date, created_at, updated_at

---

### Tags

| Command | API | Description |
|---------|-----|-------------|
| `list tags` | GET /tags | List all tags |
| `add tag <name>` | POST /tags | Create a tag |
| `get tag <id>` | GET /tags/:id | Get tag details |
| `update tag <id>` | PATCH /tags/:id | Update a tag |
| `delete tag <id>` | DELETE /tags/:id | Delete a tag |

**Tag Options:**
- `--color` — Tag color (hex code)

**Tag Fields:** id, name, color, created_at

---

## API Call Examples

```bash
# Read config
CONFIG=$(cat ~/.flowmind/config.json)
API_KEY=$(echo $CONFIG | jq -r '.api_key')
BASE_URL=$(echo $CONFIG | jq -r '.base_url')

# List goals
curl -s "$BASE_URL/goals" -H "Authorization: Bearer $API_KEY"

# Create task
curl -s -X POST "$BASE_URL/tasks" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"title": "My task", "priority": "high", "due_date": "2025-01-15"}'

# Update task
curl -s -X PATCH "$BASE_URL/tasks/abc123" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'

# Delete goal
curl -s -X DELETE "$BASE_URL/goals/xyz789" \
  -H "Authorization: Bearer $API_KEY"

# Create person
curl -s -X POST "$BASE_URL/people" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "relationship_type": "colleague"}'
```

---

## Pagination

For list commands, use:
- `--page` — Page number (default: 1)
- `--limit` — Items per page (default: 20, max: 100)

API returns: `{ data: [...], meta: { pagination: { page, limit, total, totalPages, hasMore } } }`

---

## Present Results

- **Created/Updated:** Show item title, ID, and key fields
- **Lists:** Format as clean table with relevant columns
- **Deleted:** Confirm deletion with item title
- **Errors:** Explain what went wrong and suggest fix

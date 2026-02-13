---
name: flowmind
description: Manage goals, tasks, and notes with FlowMind. Use when user wants to create/list/update tasks, goals, or notes, track productivity, or manage their focus.
---

## FlowMind Productivity Skill

Connect to [FlowMind](https://flowmind.life) to manage goals, tasks, and notes.

## Setup

User needs to configure their API key first:

```bash
# Create config directory
mkdir -p ~/.flowmind

# Save API key (user gets this from FlowMind Settings > API Keys)
echo '{"api_key": "fm_xxx", "base_url": "https://flowmind.life/api/v1"}' > ~/.flowmind/config.json
```

## Usage Examples

<example>
User: /flowmind add task "Review quarterly report" with high priority due tomorrow
Assistant: [Creates task via API, confirms creation with task ID]
</example>

<example>
User: /flowmind list my tasks
Assistant: [Fetches and displays tasks from API]
</example>

<example>
User: /flowmind add goal "Launch MVP" in business category
Assistant: [Creates goal via API, confirms creation]
</example>

## Instructions

When user invokes this skill:

### 1. Check Configuration

First, read the config file:
```bash
cat ~/.flowmind/config.json
```

If missing or invalid, guide user to set it up:
1. Go to https://flowmind.life and sign in
2. Click avatar → Settings → API Keys
3. Generate new key (starts with `fm_`)
4. Run: `echo '{"api_key": "fm_YOUR_KEY", "base_url": "https://flowmind.life/api/v1"}' > ~/.flowmind/config.json`

### 2. Parse User Request

Understand what the user wants:
- **add task** → POST /tasks
- **add goal** → POST /goals  
- **add note** → POST /notes
- **list tasks** → GET /tasks
- **list goals** → GET /goals
- **list notes** → GET /notes
- **focus** → GET /tasks?is_focus=true or PATCH /tasks/:id

### 3. Make API Calls

Use curl with the API key from config:

```bash
# Example: Create a task
curl -s -X POST "${BASE_URL}/tasks" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Task title", "priority": "high", "due_date": "2025-01-15"}'

# Example: List tasks
curl -s -X GET "${BASE_URL}/tasks" \
  -H "Authorization: Bearer ${API_KEY}"

# Example: Create a goal
curl -s -X POST "${BASE_URL}/goals" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Goal title", "category": "business"}'
```

### 4. Present Results

Format the API response nicely for the user:
- For created items: Show title, ID, and key details
- For lists: Show as a clean table or bullet list
- For errors: Explain what went wrong and how to fix

## API Reference

### Tasks

| Field | Type | Description |
|-------|------|-------------|
| title | string | Task title (required) |
| description | string | Task details |
| priority | string | low, medium, high, urgent |
| status | string | todo, in_progress, completed |
| due_date | string | YYYY-MM-DD format |
| goal_id | string | Link to parent goal |
| is_focus | boolean | Today's focus task |

### Goals

| Field | Type | Description |
|-------|------|-------------|
| title | string | Goal title (required) |
| description | string | Goal details |
| category | string | business, career, health, personal, learning, financial |
| target_date | string | YYYY-MM-DD format |
| status | string | active, completed, archived |

### Notes

| Field | Type | Description |
|-------|------|-------------|
| title | string | Note title (required) |
| content | string | Note body (markdown supported) |
| tags | array | List of tag strings |
| goal_id | string | Link to related goal |

## Common Commands

- `/flowmind add task "title"` - Create a task
- `/flowmind add task "title" --priority high --due 2025-01-15` - Task with options
- `/flowmind add goal "title" --category business` - Create a goal
- `/flowmind add note "title"` - Create a note
- `/flowmind list tasks` - Show all tasks
- `/flowmind list tasks --status todo` - Filter by status
- `/flowmind list goals` - Show all goals
- `/flowmind focus` - Show today's focus tasks
- `/flowmind focus <task_id>` - Set task as focus

#!/bin/bash
#
# FlowMind CLI - Connect to FlowMind API
# https://flowmind.life
#

set -e

CONFIG_DIR="$HOME/.flowmind"
CONFIG_FILE="$CONFIG_DIR/config.json"
API_BASE="https://flowmind.life/api/v1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
error() { echo -e "${RED}Error:${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

# Get API key from config
get_api_key() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "Not configured. Run: flowmind config <api_key>"
    fi
    API_KEY=$(jq -r '.api_key // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -z "$API_KEY" ]]; then
        error "API key not found in config. Run: flowmind config <api_key>"
    fi
    echo "$API_KEY"
}

# API request helper
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local api_key
    api_key=$(get_api_key)
    
    local args=(-s -X "$method" --connect-timeout 10 --max-time 30)
    args+=(-H "Authorization: Bearer $api_key")
    args+=(-H "Content-Type: application/json")
    
    if [[ -n "$data" ]]; then
        args+=(-d "$data")
    fi
    
    local response
    if ! response=$(curl "${args[@]}" "$API_BASE$endpoint" 2>/dev/null); then
        error "Network request failed"
    fi
    
    # Check for errors (only if error is truthy)
    if echo "$response" | jq -e '.error // empty | select(. != null and . != false and . != "")' >/dev/null 2>&1; then
        local err_msg
        err_msg=$(echo "$response" | jq -r '.error.message // .error // "Unknown error"')
        error "$err_msg"
    fi
    
    echo "$response"
}

# Commands
cmd_config() {
    local api_key="$1"
    
    if [[ -z "$api_key" ]]; then
        echo ""
        echo "FlowMind Configuration"
        echo "======================"
        echo ""
        echo "To get your API key:"
        echo "  1. Go to https://flowmind.life and sign in"
        echo "  2. Click your avatar → Settings"
        echo "  3. Navigate to API Keys"
        echo "  4. Click 'Generate New Key'"
        echo "  5. Copy the key (starts with 'fm_')"
        echo ""
        echo "Usage: flowmind config <your_api_key>"
        echo ""
        
        if [[ -f "$CONFIG_FILE" ]]; then
            local existing_key=$(jq -r '.api_key // empty' "$CONFIG_FILE" 2>/dev/null)
            if [[ -n "$existing_key" ]]; then
                echo "Current key: ${existing_key:0:10}..."
            fi
        fi
        return
    fi
    
    # Validate key format
    if [[ ! "$api_key" =~ ^fm_ ]]; then
        warn "API key should start with 'fm_'. Are you sure this is correct?"
    fi
    
    # Create config directory with secure permissions
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    # Save config safely with jq
    jq -n --arg key "$api_key" '{api_key: $key}' > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    success "API key saved to $CONFIG_FILE"
    
    # Test connection
    info "Testing connection..."
    if api_request GET "/goals?limit=1" >/dev/null 2>&1; then
        success "Connected to FlowMind successfully!"
    else
        warn "Could not verify connection. Please check your API key."
    fi
}

cmd_add_task() {
    local title=""
    local description=""
    local priority="medium"
    local due_date=""
    local goal_id=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description)
                description="$2"; shift 2 ;;
            -p|--priority)
                priority="$2"; shift 2 ;;
            --due)
                due_date="$2"; shift 2 ;;
            --goal)
                goal_id="$2"; shift 2 ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                if [[ -z "$title" ]]; then
                    title="$1"
                fi
                shift ;;
        esac
    done
    
    if [[ -z "$title" ]]; then
        error "Task title is required. Usage: flowmind add-task \"Task title\" [options]"
    fi
    
    # Validate priority
    if [[ -n "$priority" ]]; then
        case "$priority" in
            low|medium|high|urgent) ;;
            *) error "Invalid priority. Use: low, medium, high, urgent" ;;
        esac
    fi
    
    # Build JSON payload safely with jq
    local json
    json=$(jq -n \
        --arg title "$title" \
        --arg desc "$description" \
        --arg prio "$priority" \
        --arg due "$due_date" \
        --arg goal "$goal_id" \
        '{title: $title} + 
         (if $desc != "" then {description: $desc} else {} end) +
         (if $prio != "" then {priority: $prio} else {} end) +
         (if $due != "" then {due_date: $due} else {} end) +
         (if $goal != "" then {goal_id: $goal} else {} end)')
    
    local response
    response=$(api_request POST "/tasks" "$json")
    
    local task_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Task created: $title"
    [[ -n "$task_id" ]] && echo "  ID: $task_id"
}

cmd_add_goal() {
    local title=""
    local description=""
    local category=""
    local target_date=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description)
                description="$2"; shift 2 ;;
            -c|--category)
                category="$2"; shift 2 ;;
            --target)
                target_date="$2"; shift 2 ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                if [[ -z "$title" ]]; then
                    title="$1"
                fi
                shift ;;
        esac
    done
    
    if [[ -z "$title" ]]; then
        error "Goal title is required. Usage: flowmind add-goal \"Goal title\" [options]"
    fi
    
    # Validate category
    if [[ -n "$category" ]]; then
        case "$category" in
            business|career|health|personal|learning|financial) ;;
            *) error "Invalid category. Use: business, career, health, personal, learning, financial" ;;
        esac
    fi
    
    # Build JSON payload safely with jq
    local json
    json=$(jq -n \
        --arg title "$title" \
        --arg desc "$description" \
        --arg cat "$category" \
        --arg target "$target_date" \
        '{title: $title} + 
         (if $desc != "" then {description: $desc} else {} end) +
         (if $cat != "" then {category: $cat} else {} end) +
         (if $target != "" then {target_date: $target} else {} end)')
    
    local response
    response=$(api_request POST "/goals" "$json")
    
    local goal_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Goal created: $title"
    [[ -n "$goal_id" ]] && echo "  ID: $goal_id"
}

cmd_add_note() {
    local title=""
    local content=""
    local use_stdin=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --content)
                content="$2"; shift 2 ;;
            --stdin)
                use_stdin=true; shift ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                if [[ -z "$title" ]]; then
                    title="$1"
                fi
                shift ;;
        esac
    done
    
    if [[ -z "$title" ]]; then
        error "Note title is required. Usage: flowmind add-note \"Note title\" [--content \"...\"]"
    fi
    
    # Read from stdin if requested
    if $use_stdin; then
        content=$(cat)
    fi
    
    # If no content, prompt interactively
    if [[ -z "$content" ]]; then
        echo "Enter note content (Ctrl+D when done):"
        content=$(cat)
    fi
    
    # Escape content for JSON
    content=$(echo "$content" | jq -Rs .)
    
    # Build JSON payload
    local json="{\"title\": \"$title\", \"content\": $content}"
    
    local response
    response=$(api_request POST "/notes" "$json")
    
    local note_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Note created: $title"
    [[ -n "$note_id" ]] && echo "  ID: $note_id"
}

cmd_list_tasks() {
    local status=""
    local priority=""
    local limit="20"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)
                status="$2"; shift 2 ;;
            --priority)
                priority="$2"; shift 2 ;;
            --limit)
                limit="$2"; shift 2 ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                shift ;;
        esac
    done
    
    # Build query string
    local query="?limit=$limit"
    [[ -n "$status" ]] && query+="&status=$status"
    [[ -n "$priority" ]] && query+="&priority=$priority"
    
    local response
    response=$(api_request GET "/tasks$query")
    
    echo ""
    echo "Tasks"
    echo "====="
    echo "$response" | jq -r '.data[] | "[\(.priority // "medium")] \(.title) (ID: \(.id))"' 2>/dev/null || echo "No tasks found"
    echo ""
}

cmd_list_goals() {
    local status=""
    local category=""
    local limit="20"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)
                status="$2"; shift 2 ;;
            --category)
                category="$2"; shift 2 ;;
            --limit)
                limit="$2"; shift 2 ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                shift ;;
        esac
    done
    
    # Build query string
    local query="?limit=$limit"
    [[ -n "$status" ]] && query+="&status=$status"
    [[ -n "$category" ]] && query+="&category=$category"
    
    local response
    response=$(api_request GET "/goals$query")
    
    echo ""
    echo "Goals"
    echo "====="
    echo "$response" | jq -r '.data[] | "[\(.category // "general")] \(.title) - \(.progress // 0)% (ID: \(.id))"' 2>/dev/null || echo "No goals found"
    echo ""
}

cmd_list_notes() {
    local limit="20"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit)
                limit="$2"; shift 2 ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                shift ;;
        esac
    done
    
    local response
    response=$(api_request GET "/notes?limit=$limit")
    
    echo ""
    echo "Notes"
    echo "====="
    echo "$response" | jq -r '.data[] | "\(.title) (ID: \(.id))"' 2>/dev/null || echo "No notes found"
    echo ""
}

cmd_focus() {
    local task_id=""
    local list_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list|-l)
                list_mode=true; shift ;;
            -*)
                error "Unknown option: $1" ;;
            *)
                task_id="$1"; shift ;;
        esac
    done
    
    if $list_mode; then
        # List today's focus tasks
        local response
        response=$(api_request GET "/tasks?focus_today=true")
        
        echo ""
        echo "Today's Focus"
        echo "============="
        echo "$response" | jq -r '.data[] | "• \(.title) [\(.priority // "medium")]"' 2>/dev/null || echo "No focus tasks set for today"
        echo ""
        return
    fi
    
    if [[ -z "$task_id" ]]; then
        error "Task ID required. Usage: flowmind focus <task_id> or flowmind focus --list"
    fi
    
    # Set task as today's focus
    local response
    response=$(api_request PATCH "/tasks/$task_id" '{"focus_today": true}')
    
    local title=$(echo "$response" | jq -r '.data.title // .title // "Task"')
    success "Set as today's focus: $title"
}

cmd_help() {
    echo ""
    echo "FlowMind CLI"
    echo "============"
    echo ""
    echo "Usage: flowmind <command> [options]"
    echo ""
    echo "Commands:"
    echo "  config [api_key]     Configure API key"
    echo "  add-task <title>     Create a new task"
    echo "  add-goal <title>     Create a new goal"
    echo "  add-note <title>     Create a new note"
    echo "  list-tasks           List tasks"
    echo "  list-goals           List goals"
    echo "  list-notes           List notes"
    echo "  focus <task_id>      Set task as today's focus"
    echo "  focus --list         List today's focus tasks"
    echo "  help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  flowmind config fm_abc123..."
    echo "  flowmind add-task \"Review code\" -p high --due 2026-03-15"
    echo "  flowmind add-goal \"Launch MVP\" -c business --target 2026-06-01"
    echo "  flowmind list-tasks --status todo --priority high"
    echo ""
    echo "Documentation: https://docs.flowmind.life"
    echo ""
}

# Main entry point
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        config)
            cmd_config "$@" ;;
        add-task)
            cmd_add_task "$@" ;;
        add-goal)
            cmd_add_goal "$@" ;;
        add-note)
            cmd_add_note "$@" ;;
        list-tasks)
            cmd_list_tasks "$@" ;;
        list-goals)
            cmd_list_goals "$@" ;;
        list-notes)
            cmd_list_notes "$@" ;;
        focus)
            cmd_focus "$@" ;;
        help|--help|-h)
            cmd_help ;;
        *)
            error "Unknown command: $command. Run 'flowmind help' for usage." ;;
    esac
}

main "$@"

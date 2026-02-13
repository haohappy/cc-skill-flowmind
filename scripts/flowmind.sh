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
CYAN='\033[0;36m'
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
    local key
    key=$(jq -r '.api_key // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -z "$key" ]]; then
        error "API key not found in config. Run: flowmind config <api_key>"
    fi
    echo "$key"
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

# ============================================================================
# CONFIG
# ============================================================================

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
            local existing_key
            existing_key=$(jq -r '.api_key // empty' "$CONFIG_FILE" 2>/dev/null)
            if [[ -n "$existing_key" ]]; then
                echo "Current key: ${existing_key:0:10}..."
            fi
        fi
        return
    fi
    
    if [[ ! "$api_key" =~ ^fm_ ]]; then
        warn "API key should start with 'fm_'. Are you sure this is correct?"
    fi
    
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    jq -n --arg key "$api_key" '{api_key: $key}' > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    success "API key saved to $CONFIG_FILE"
    
    info "Testing connection..."
    if api_request GET "/goals?limit=1" >/dev/null 2>&1; then
        success "Connected to FlowMind successfully!"
    else
        warn "Could not verify connection. Please check your API key."
    fi
}

# ============================================================================
# TASKS
# ============================================================================

cmd_add_task() {
    local title="" description="" priority="" due_date="" goal_id="" energy=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description) description="$2"; shift 2 ;;
            -p|--priority) priority="$2"; shift 2 ;;
            -e|--energy) energy="$2"; shift 2 ;;
            --due) due_date="$2"; shift 2 ;;
            --goal) goal_id="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$title" ]] && title="$1"; shift ;;
        esac
    done
    
    [[ -z "$title" ]] && error "Task title required. Usage: flowmind add-task \"Title\" [options]"
    
    [[ -n "$priority" ]] && case "$priority" in
        low|medium|high|urgent) ;;
        *) error "Invalid priority. Use: low, medium, high, urgent" ;;
    esac
    
    [[ -n "$energy" ]] && case "$energy" in
        low|medium|high) ;;
        *) error "Invalid energy. Use: low, medium, high" ;;
    esac
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg desc "$description" --arg prio "$priority" \
        --arg due "$due_date" --arg goal "$goal_id" --arg energy "$energy" \
        '{title: $title} + 
         (if $desc != "" then {description: $desc} else {} end) +
         (if $prio != "" then {priority: $prio} else {} end) +
         (if $energy != "" then {energy_level: $energy} else {} end) +
         (if $due != "" then {due_date: $due} else {} end) +
         (if $goal != "" then {goal_id: $goal} else {} end)')
    
    local response
    response=$(api_request POST "/tasks" "$json")
    
    local task_id
    task_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Task created: $title"
    [[ -n "$task_id" ]] && echo "  ID: $task_id"
}

cmd_get_task() {
    local task_id="$1"
    [[ -z "$task_id" ]] && error "Task ID required. Usage: flowmind get-task <task_id>"
    
    local response
    response=$(api_request GET "/tasks/$task_id")
    
    echo "$response" | jq -r '.data // . | "Title: \(.title)\nStatus: \(.status // "todo")\nPriority: \(.priority // "medium")\nDue: \(.due_date // "none")\nDescription: \(.description // "none")\nGoal ID: \(.goal_id // "none")\nID: \(.id)"'
}

cmd_update_task() {
    local task_id="" title="" description="" status="" priority="" due_date=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            -d|--description) description="$2"; shift 2 ;;
            -s|--status) status="$2"; shift 2 ;;
            -p|--priority) priority="$2"; shift 2 ;;
            --due) due_date="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$task_id" ]] && task_id="$1"; shift ;;
        esac
    done
    
    [[ -z "$task_id" ]] && error "Task ID required. Usage: flowmind update-task <task_id> [options]"
    
    [[ -n "$status" ]] && case "$status" in
        todo|in_progress|completed|archived) ;;
        *) error "Invalid status. Use: todo, in_progress, completed, archived" ;;
    esac
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg desc "$description" --arg status "$status" \
        --arg prio "$priority" --arg due "$due_date" \
        '(if $title != "" then {title: $title} else {} end) +
         (if $desc != "" then {description: $desc} else {} end) +
         (if $status != "" then {status: $status} else {} end) +
         (if $prio != "" then {priority: $prio} else {} end) +
         (if $due != "" then {due_date: $due} else {} end)')
    
    local response
    response=$(api_request PATCH "/tasks/$task_id" "$json")
    success "Task updated"
}

cmd_delete_task() {
    local task_id="$1"
    [[ -z "$task_id" ]] && error "Task ID required. Usage: flowmind delete-task <task_id>"
    
    api_request DELETE "/tasks/$task_id" >/dev/null
    success "Task deleted"
}

cmd_list_tasks() {
    local status="" priority="" goal_id="" limit="20"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status) status="$2"; shift 2 ;;
            --priority) priority="$2"; shift 2 ;;
            --goal) goal_id="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) shift ;;
        esac
    done
    
    local query="?limit=$limit"
    [[ -n "$status" ]] && query+="&status=$status"
    [[ -n "$priority" ]] && query+="&priority=$priority"
    [[ -n "$goal_id" ]] && query+="&goal_id=$goal_id"
    
    local response
    response=$(api_request GET "/tasks$query")
    
    echo ""
    echo -e "${CYAN}Tasks${NC}"
    echo "======"
    echo "$response" | jq -r '.data[] | "[\(.priority // "medium")] \(.title) (\(.status // "todo")) - ID: \(.id)"' 2>/dev/null || echo "No tasks found"
    echo ""
}

cmd_add_subtask() {
    local parent_id="" title="" description="" priority=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --parent) parent_id="$2"; shift 2 ;;
            -d|--description) description="$2"; shift 2 ;;
            -p|--priority) priority="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$title" ]] && title="$1"; shift ;;
        esac
    done
    
    [[ -z "$parent_id" ]] && error "Parent task ID required. Usage: flowmind add-subtask \"Title\" --parent <task_id>"
    [[ -z "$title" ]] && error "Subtask title required"
    
    local json
    json=$(jq -n --arg title "$title" --arg desc "$description" --arg prio "$priority" \
        '{title: $title} + 
         (if $desc != "" then {description: $desc} else {} end) +
         (if $prio != "" then {priority: $prio} else {} end)')
    
    local response
    response=$(api_request POST "/tasks/$parent_id/subtasks" "$json")
    success "Subtask created: $title"
}

cmd_list_subtasks() {
    local task_id="$1"
    [[ -z "$task_id" ]] && error "Task ID required. Usage: flowmind list-subtasks <task_id>"
    
    local response
    response=$(api_request GET "/tasks/$task_id/subtasks")
    
    echo ""
    echo -e "${CYAN}Subtasks${NC}"
    echo "========="
    echo "$response" | jq -r '.data[] | "  • \(.title) [\(.status // "todo")]"' 2>/dev/null || echo "No subtasks found"
    echo ""
}

cmd_focus() {
    local task_id="" list_mode=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list|-l) list_mode=true; shift ;;
            -*) error "Unknown option: $1" ;;
            *) task_id="$1"; shift ;;
        esac
    done
    
    if $list_mode; then
        local response
        response=$(api_request GET "/tasks?focus_today=true")
        echo ""
        echo -e "${CYAN}Today's Focus${NC}"
        echo "=============="
        echo "$response" | jq -r '.data[] | "• \(.title) [\(.priority // "medium")]"' 2>/dev/null || echo "No focus tasks"
        echo ""
        return
    fi
    
    [[ -z "$task_id" ]] && error "Task ID required. Usage: flowmind focus <task_id>"
    
    local response
    response=$(api_request PATCH "/tasks/$task_id" '{"focus_today": true}')
    success "Set as today's focus"
}

# ============================================================================
# GOALS
# ============================================================================

cmd_add_goal() {
    local title="" description="" category="" target_date=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--description) description="$2"; shift 2 ;;
            -c|--category) category="$2"; shift 2 ;;
            --target) target_date="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$title" ]] && title="$1"; shift ;;
        esac
    done
    
    [[ -z "$title" ]] && error "Goal title required. Usage: flowmind add-goal \"Title\" [options]"
    
    [[ -n "$category" ]] && case "$category" in
        business|career|health|personal|learning|financial) ;;
        *) error "Invalid category. Use: business, career, health, personal, learning, financial" ;;
    esac
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg desc "$description" \
        --arg cat "$category" --arg target "$target_date" \
        '{title: $title} + 
         (if $desc != "" then {description: $desc} else {} end) +
         (if $cat != "" then {category: $cat} else {} end) +
         (if $target != "" then {target_date: $target} else {} end)')
    
    local response
    response=$(api_request POST "/goals" "$json")
    
    local goal_id
    goal_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Goal created: $title"
    [[ -n "$goal_id" ]] && echo "  ID: $goal_id"
}

cmd_get_goal() {
    local goal_id="$1"
    [[ -z "$goal_id" ]] && error "Goal ID required. Usage: flowmind get-goal <goal_id>"
    
    local response
    response=$(api_request GET "/goals/$goal_id")
    
    echo "$response" | jq -r '.data // . | "Title: \(.title)\nStatus: \(.status // "active")\nCategory: \(.category // "none")\nProgress: \(.progress // 0)%\nTarget: \(.target_date // "none")\nDescription: \(.description // "none")\nID: \(.id)"'
}

cmd_update_goal() {
    local goal_id="" title="" description="" status="" category="" progress=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            -d|--description) description="$2"; shift 2 ;;
            -s|--status) status="$2"; shift 2 ;;
            -c|--category) category="$2"; shift 2 ;;
            --progress) progress="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$goal_id" ]] && goal_id="$1"; shift ;;
        esac
    done
    
    [[ -z "$goal_id" ]] && error "Goal ID required. Usage: flowmind update-goal <goal_id> [options]"
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg desc "$description" --arg status "$status" \
        --arg cat "$category" --argjson prog "${progress:-null}" \
        '(if $title != "" then {title: $title} else {} end) +
         (if $desc != "" then {description: $desc} else {} end) +
         (if $status != "" then {status: $status} else {} end) +
         (if $cat != "" then {category: $cat} else {} end) +
         (if $prog != null then {progress: $prog} else {} end)')
    
    api_request PATCH "/goals/$goal_id" "$json" >/dev/null
    success "Goal updated"
}

cmd_delete_goal() {
    local goal_id="$1"
    [[ -z "$goal_id" ]] && error "Goal ID required. Usage: flowmind delete-goal <goal_id>"
    
    api_request DELETE "/goals/$goal_id" >/dev/null
    success "Goal deleted"
}

cmd_list_goals() {
    local status="" category="" limit="20"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status) status="$2"; shift 2 ;;
            --category) category="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) shift ;;
        esac
    done
    
    local query="?limit=$limit"
    [[ -n "$status" ]] && query+="&status=$status"
    [[ -n "$category" ]] && query+="&category=$category"
    
    local response
    response=$(api_request GET "/goals$query")
    
    echo ""
    echo -e "${CYAN}Goals${NC}"
    echo "======"
    echo "$response" | jq -r '.data[] | "[\(.category // "general")] \(.title) - \(.progress // 0)% - ID: \(.id)"' 2>/dev/null || echo "No goals found"
    echo ""
}

cmd_goal_tasks() {
    local goal_id="$1"
    [[ -z "$goal_id" ]] && error "Goal ID required. Usage: flowmind goal-tasks <goal_id>"
    
    local response
    response=$(api_request GET "/goals/$goal_id/tasks")
    
    echo ""
    echo -e "${CYAN}Tasks for Goal${NC}"
    echo "==============="
    echo "$response" | jq -r '.data[] | "[\(.priority // "medium")] \(.title) - \(.status // "todo")"' 2>/dev/null || echo "No tasks found"
    echo ""
}

# ============================================================================
# NOTES
# ============================================================================

cmd_add_note() {
    local title="" content="" category="" task_id=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --content) content="$2"; shift 2 ;;
            -c|--category) category="$2"; shift 2 ;;
            --task) task_id="$2"; shift 2 ;;
            --stdin) content=$(cat); shift ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$title" ]] && title="$1"; shift ;;
        esac
    done
    
    [[ -z "$title" ]] && error "Note title required. Usage: flowmind add-note \"Title\" [--content \"...\"]"
    
    if [[ -z "$content" ]] && [[ -t 0 ]]; then
        echo "Enter note content (Ctrl+D when done):"
        content=$(cat)
    fi
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg content "$content" \
        --arg cat "$category" --arg task "$task_id" \
        '{title: $title} + 
         (if $content != "" then {content: $content} else {} end) +
         (if $cat != "" then {category: $cat} else {} end) +
         (if $task != "" then {task_id: $task} else {} end)')
    
    local response
    response=$(api_request POST "/notes" "$json")
    
    local note_id
    note_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Note created: $title"
    [[ -n "$note_id" ]] && echo "  ID: $note_id"
}

cmd_get_note() {
    local note_id="$1"
    [[ -z "$note_id" ]] && error "Note ID required. Usage: flowmind get-note <note_id>"
    
    local response
    response=$(api_request GET "/notes/$note_id")
    
    echo "$response" | jq -r '.data // . | "Title: \(.title)\nCategory: \(.category // "none")\nContent:\n\(.content // "(empty)")\nID: \(.id)"'
}

cmd_update_note() {
    local note_id="" title="" content="" category=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            --content) content="$2"; shift 2 ;;
            -c|--category) category="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$note_id" ]] && note_id="$1"; shift ;;
        esac
    done
    
    [[ -z "$note_id" ]] && error "Note ID required. Usage: flowmind update-note <note_id> [options]"
    
    local json
    json=$(jq -n \
        --arg title "$title" --arg content "$content" --arg cat "$category" \
        '(if $title != "" then {title: $title} else {} end) +
         (if $content != "" then {content: $content} else {} end) +
         (if $cat != "" then {category: $cat} else {} end)')
    
    api_request PATCH "/notes/$note_id" "$json" >/dev/null
    success "Note updated"
}

cmd_delete_note() {
    local note_id="$1"
    [[ -z "$note_id" ]] && error "Note ID required. Usage: flowmind delete-note <note_id>"
    
    api_request DELETE "/notes/$note_id" >/dev/null
    success "Note deleted"
}

cmd_list_notes() {
    local category="" limit="20"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--category) category="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) shift ;;
        esac
    done
    
    local query="?limit=$limit"
    [[ -n "$category" ]] && query+="&category=$category"
    
    local response
    response=$(api_request GET "/notes$query")
    
    echo ""
    echo -e "${CYAN}Notes${NC}"
    echo "======"
    echo "$response" | jq -r '.data[] | "\(.title) - ID: \(.id)"' 2>/dev/null || echo "No notes found"
    echo ""
}

# ============================================================================
# PEOPLE
# ============================================================================

cmd_add_person() {
    local name="" email="" phone="" company="" role="" relationship="" notes=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --email) email="$2"; shift 2 ;;
            --phone) phone="$2"; shift 2 ;;
            --company) company="$2"; shift 2 ;;
            --role) role="$2"; shift 2 ;;
            -r|--relationship) relationship="$2"; shift 2 ;;
            --notes) notes="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$name" ]] && name="$1"; shift ;;
        esac
    done
    
    [[ -z "$name" ]] && error "Name required. Usage: flowmind add-person \"Name\" [options]"
    
    [[ -n "$relationship" ]] && case "$relationship" in
        business|colleague|friend|family|mentor|client|partner|other) ;;
        *) error "Invalid relationship. Use: business, colleague, friend, family, mentor, client, partner, other" ;;
    esac
    
    local json
    json=$(jq -n \
        --arg name "$name" --arg email "$email" --arg phone "$phone" \
        --arg company "$company" --arg role "$role" \
        --arg rel "$relationship" --arg notes "$notes" \
        '{name: $name} + 
         (if $email != "" then {email: $email} else {} end) +
         (if $phone != "" then {phone: $phone} else {} end) +
         (if $company != "" then {company: $company} else {} end) +
         (if $role != "" then {role: $role} else {} end) +
         (if $rel != "" then {relationship_type: $rel} else {} end) +
         (if $notes != "" then {notes: $notes} else {} end)')
    
    local response
    response=$(api_request POST "/people" "$json")
    
    local person_id
    person_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Person added: $name"
    [[ -n "$person_id" ]] && echo "  ID: $person_id"
}

cmd_get_person() {
    local person_id="$1"
    [[ -z "$person_id" ]] && error "Person ID required. Usage: flowmind get-person <person_id>"
    
    local response
    response=$(api_request GET "/people/$person_id")
    
    echo "$response" | jq -r '.data // . | "Name: \(.name)\nEmail: \(.email // "none")\nPhone: \(.phone // "none")\nCompany: \(.company // "none")\nRole: \(.role // "none")\nRelationship: \(.relationship_type // "none")\nNotes: \(.notes // "none")\nID: \(.id)"'
}

cmd_update_person() {
    local person_id="" name="" email="" phone="" company="" role="" relationship=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name) name="$2"; shift 2 ;;
            --email) email="$2"; shift 2 ;;
            --phone) phone="$2"; shift 2 ;;
            --company) company="$2"; shift 2 ;;
            --role) role="$2"; shift 2 ;;
            -r|--relationship) relationship="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$person_id" ]] && person_id="$1"; shift ;;
        esac
    done
    
    [[ -z "$person_id" ]] && error "Person ID required. Usage: flowmind update-person <person_id> [options]"
    
    local json
    json=$(jq -n \
        --arg name "$name" --arg email "$email" --arg phone "$phone" \
        --arg company "$company" --arg role "$role" --arg rel "$relationship" \
        '(if $name != "" then {name: $name} else {} end) +
         (if $email != "" then {email: $email} else {} end) +
         (if $phone != "" then {phone: $phone} else {} end) +
         (if $company != "" then {company: $company} else {} end) +
         (if $role != "" then {role: $role} else {} end) +
         (if $rel != "" then {relationship_type: $rel} else {} end)')
    
    api_request PATCH "/people/$person_id" "$json" >/dev/null
    success "Person updated"
}

cmd_delete_person() {
    local person_id="$1"
    [[ -z "$person_id" ]] && error "Person ID required. Usage: flowmind delete-person <person_id>"
    
    api_request DELETE "/people/$person_id" >/dev/null
    success "Person deleted"
}

cmd_list_people() {
    local relationship="" search="" limit="20"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--relationship) relationship="$2"; shift 2 ;;
            -s|--search) search="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) shift ;;
        esac
    done
    
    local query="?limit=$limit"
    [[ -n "$relationship" ]] && query+="&relationship_type=$relationship"
    [[ -n "$search" ]] && query+="&search=$search"
    
    local response
    response=$(api_request GET "/people$query")
    
    echo ""
    echo -e "${CYAN}People${NC}"
    echo "======="
    echo "$response" | jq -r '.data[] | "\(.name) [\(.relationship_type // "other")] - ID: \(.id)"' 2>/dev/null || echo "No people found"
    echo ""
}

# ============================================================================
# TAGS
# ============================================================================

cmd_add_tag() {
    local name="" color=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --color) color="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$name" ]] && name="$1"; shift ;;
        esac
    done
    
    [[ -z "$name" ]] && error "Tag name required. Usage: flowmind add-tag \"Name\" [--color #hex]"
    
    local json
    json=$(jq -n --arg name "$name" --arg color "$color" \
        '{name: $name} + (if $color != "" then {color: $color} else {} end)')
    
    local response
    response=$(api_request POST "/tags" "$json")
    
    local tag_id
    tag_id=$(echo "$response" | jq -r '.data.id // .id // empty')
    success "Tag created: $name"
    [[ -n "$tag_id" ]] && echo "  ID: $tag_id"
}

cmd_get_tag() {
    local tag_id="$1"
    [[ -z "$tag_id" ]] && error "Tag ID required. Usage: flowmind get-tag <tag_id>"
    
    local response
    response=$(api_request GET "/tags/$tag_id")
    
    echo "$response" | jq -r '.data // . | "Name: \(.name)\nColor: \(.color // "none")\nID: \(.id)"'
}

cmd_update_tag() {
    local tag_id="" name="" color=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name) name="$2"; shift 2 ;;
            --color) color="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) [[ -z "$tag_id" ]] && tag_id="$1"; shift ;;
        esac
    done
    
    [[ -z "$tag_id" ]] && error "Tag ID required. Usage: flowmind update-tag <tag_id> [options]"
    
    local json
    json=$(jq -n --arg name "$name" --arg color "$color" \
        '(if $name != "" then {name: $name} else {} end) +
         (if $color != "" then {color: $color} else {} end)')
    
    api_request PATCH "/tags/$tag_id" "$json" >/dev/null
    success "Tag updated"
}

cmd_delete_tag() {
    local tag_id="$1"
    [[ -z "$tag_id" ]] && error "Tag ID required. Usage: flowmind delete-tag <tag_id>"
    
    api_request DELETE "/tags/$tag_id" >/dev/null
    success "Tag deleted"
}

cmd_list_tags() {
    local limit="50"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) limit="$2"; shift 2 ;;
            -*) error "Unknown option: $1" ;;
            *) shift ;;
        esac
    done
    
    local response
    response=$(api_request GET "/tags?limit=$limit")
    
    echo ""
    echo -e "${CYAN}Tags${NC}"
    echo "====="
    echo "$response" | jq -r '.data[] | "\(.name) [\(.color // "no color")] - ID: \(.id)"' 2>/dev/null || echo "No tags found"
    echo ""
}

# ============================================================================
# HELP
# ============================================================================

cmd_help() {
    echo ""
    echo -e "${CYAN}FlowMind CLI${NC}"
    echo "============="
    echo ""
    echo "Usage: flowmind <command> [options]"
    echo ""
    echo -e "${YELLOW}Setup${NC}"
    echo "  config [api_key]       Configure API key"
    echo ""
    echo -e "${YELLOW}Tasks${NC}"
    echo "  add-task <title>       Create task"
    echo "  get-task <id>          Get task details"
    echo "  update-task <id>       Update task"
    echo "  delete-task <id>       Delete task"
    echo "  list-tasks             List tasks"
    echo "  add-subtask <title>    Create subtask (--parent <id>)"
    echo "  list-subtasks <id>     List subtasks"
    echo "  focus <id>             Set today's focus"
    echo "  focus --list           View today's focus"
    echo ""
    echo -e "${YELLOW}Goals${NC}"
    echo "  add-goal <title>       Create goal"
    echo "  get-goal <id>          Get goal details"
    echo "  update-goal <id>       Update goal"
    echo "  delete-goal <id>       Delete goal"
    echo "  list-goals             List goals"
    echo "  goal-tasks <id>        List tasks for goal"
    echo ""
    echo -e "${YELLOW}Notes${NC}"
    echo "  add-note <title>       Create note"
    echo "  get-note <id>          Get note"
    echo "  update-note <id>       Update note"
    echo "  delete-note <id>       Delete note"
    echo "  list-notes             List notes"
    echo ""
    echo -e "${YELLOW}People${NC}"
    echo "  add-person <name>      Add person"
    echo "  get-person <id>        Get person"
    echo "  update-person <id>     Update person"
    echo "  delete-person <id>     Delete person"
    echo "  list-people            List people"
    echo ""
    echo -e "${YELLOW}Tags${NC}"
    echo "  add-tag <name>         Create tag"
    echo "  get-tag <id>           Get tag"
    echo "  update-tag <id>        Update tag"
    echo "  delete-tag <id>        Delete tag"
    echo "  list-tags              List tags"
    echo ""
    echo "Documentation: https://docs.flowmind.life"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        # Config
        config) cmd_config "$@" ;;
        
        # Tasks
        add-task) cmd_add_task "$@" ;;
        get-task) cmd_get_task "$@" ;;
        update-task) cmd_update_task "$@" ;;
        delete-task) cmd_delete_task "$@" ;;
        list-tasks) cmd_list_tasks "$@" ;;
        add-subtask) cmd_add_subtask "$@" ;;
        list-subtasks) cmd_list_subtasks "$@" ;;
        focus) cmd_focus "$@" ;;
        
        # Goals
        add-goal) cmd_add_goal "$@" ;;
        get-goal) cmd_get_goal "$@" ;;
        update-goal) cmd_update_goal "$@" ;;
        delete-goal) cmd_delete_goal "$@" ;;
        list-goals) cmd_list_goals "$@" ;;
        goal-tasks) cmd_goal_tasks "$@" ;;
        
        # Notes
        add-note) cmd_add_note "$@" ;;
        get-note) cmd_get_note "$@" ;;
        update-note) cmd_update_note "$@" ;;
        delete-note) cmd_delete_note "$@" ;;
        list-notes) cmd_list_notes "$@" ;;
        
        # People
        add-person) cmd_add_person "$@" ;;
        get-person) cmd_get_person "$@" ;;
        update-person) cmd_update_person "$@" ;;
        delete-person) cmd_delete_person "$@" ;;
        list-people) cmd_list_people "$@" ;;
        
        # Tags
        add-tag) cmd_add_tag "$@" ;;
        get-tag) cmd_get_tag "$@" ;;
        update-tag) cmd_update_tag "$@" ;;
        delete-tag) cmd_delete_tag "$@" ;;
        list-tags) cmd_list_tags "$@" ;;
        
        # Help
        help|--help|-h) cmd_help ;;
        
        *) error "Unknown command: $command. Run 'flowmind help' for usage." ;;
    esac
}

main "$@"
